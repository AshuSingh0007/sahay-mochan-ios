import Combine
import AVFoundation
import Foundation
import UIKit

@MainActor
final class SahayViewModel: ObservableObject {
    @Published var responses = Array(repeating: 0, count: GAD7.questions.count)
    @Published var auFrames: [AUFrame] = []
    @Published var result: AssessmentResult?
    @Published var recordedVideoURL: URL?
    @Published var isProcessing = false
    @Published var isUploading = false
    @Published var uploadProgress = 0.0
    @Published var uploadMessage: String?
    @Published var errorMessage: String?
    @Published var currentQuestionIndex = 0
    @Published var liveAIScore: Double?

    private let landmarker = FaceLandmarkerService()
    private var frameCounter = 0
    private var isAnalyzingFrame = false

    var score: Int { responses.reduce(0, +) }
    var currentQuestion: QuestionnaireQuestion { GAD7.questions[currentQuestionIndex] }
    var isLastQuestion: Bool { currentQuestionIndex == GAD7.questions.count - 1 }
    var answeredQuestionCount: Int { min(currentQuestionIndex + 1, GAD7.questions.count) }

    func reset() {
        responses = Array(repeating: 0, count: GAD7.questions.count)
        auFrames = []
        result = nil
        recordedVideoURL = nil
        isProcessing = false
        isUploading = false
        uploadProgress = 0
        uploadMessage = nil
        errorMessage = nil
        currentQuestionIndex = 0
        liveAIScore = nil
        frameCounter = 0
        isAnalyzingFrame = false
    }

    func moveToNextQuestion() -> Bool {
        guard !isLastQuestion else { return false }
        currentQuestionIndex += 1
        return true
    }

    /// Call this from the assessment view after video recording finishes.
    func setRecordedVideoURL(_ url: URL) {
        recordedVideoURL = url
    }

    // Called from VideoRecorderService on background thread
    nonisolated func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let image = Self.image(from: sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        Task { @MainActor in
            await self.processImageFrame(image, timestamp: timestamp)
        }
    }

    func complete(user: User?) async {
        isProcessing = true
        errorMessage = nil
        
        // Warn if video URL is missing – the view should have set it
        if recordedVideoURL == nil {
            print("⚠️ SahayViewModel: recordedVideoURL is nil before complete()")
        }
        
        do {
            let frames = auFrames.isEmpty ? FaceLandmarkerService.sampleFrames() : auFrames
            let questionnaireScore = score
            let aiScore: Double
            
            if let liveAIScore {
                aiScore = liveAIScore
            } else {
                // Add timeout to prevent hanging (max 5 seconds)
                aiScore = await withTimeout(seconds: 5) {
                    await Task.detached(priority: .userInitiated) {
                        AnxietyModel().predict(questionnaireScore: questionnaireScore, auFrames: frames)
                    }.value
                } ?? Double(questionnaireScore) // fallback to questionnaire score
            }
            
            let auCSV = try CSVExportService.writeAUCSV(frames: frames, prefix: "sahay_au")
            let gadCSV = try CSVExportService.writeQuestionnaireCSV(type: .anxiety, responses: responses, prefix: "gad7")
            result = AssessmentResult(
                type: .anxiety,
                score: questionnaireScore,
                severity: .anxiety(score: questionnaireScore),
                aiScore: aiScore,
                videoURL: recordedVideoURL,
                auCSVURL: auCSV,
                questionnaireCSVURL: gadCSV
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func uploadResult(user: User?) async {
        guard let user, let result else {
            errorMessage = "A signed-in user and completed result are required before upload."
            return
        }

        guard result.videoURL != nil else {
            errorMessage = "Recorded video is missing. Please retake the assessment before uploading."
            return
        }

        isUploading = true
        uploadProgress = 0.15
        uploadMessage = nil
        errorMessage = nil

        do {
            uploadProgress = 0.45
            try await UploadService.shared.useTrialAndUpload(user: user, result: result)
            uploadProgress = 1.0
            uploadMessage = "Assessment uploaded."
            
            // Notify that an assessment was uploaded (for history, etc.)
            NotificationCenter.default.post(name: .assessmentDidUpload, object: nil)
            
            // ✅ Notify dashboard to refresh trial counts immediately
            NotificationCenter.default.post(name: .refreshTrials, object: nil)   // Uses definition from Extensions.swift
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploading = false
    }

    private func processImageFrame(_ image: UIImage, timestamp: TimeInterval) async {
        frameCounter += 1
        guard frameCounter % 10 == 0, !isAnalyzingFrame else { return }
        isAnalyzingFrame = true
        defer { isAnalyzingFrame = false }

        do {
            if let frame = try await landmarker.extractActionUnits(from: image, timestamp: timestamp) {
                auFrames.append(frame)
                let questionnaireScore = score
                let frames = auFrames
                liveAIScore = await Task.detached(priority: .userInitiated) {
                    AnxietyModel().predict(questionnaireScore: questionnaireScore, auFrames: frames)
                }.value
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private nonisolated static func image(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .right)
    }
}

// Helper timeout function
private func withTimeout<T>(seconds: Double, operation: @escaping () async -> T) async -> T? {
    async let task = operation()
    async let timeout = Task.sleep(UInt64(seconds * 1_000_000_000))
    let result = await (try? timeout, await task)
    if result.0 != nil { return nil }
    return await task
}

// MARK: - Notification Names
extension Notification.Name {
    static let assessmentDidUpload = Notification.Name("assessmentDidUpload")
    // ✅ refreshTrials is defined in Extensions.swift – no duplicate needed here
}
