import Combine
import Foundation

@MainActor
final class MochanViewModel: ObservableObject {
    @Published var responses = Array(repeating: 0, count: PHQ9.questions.count)
    @Published var auFrames: [AUFrame] = FaceLandmarkerService.sampleFrames()
    @Published var result: AssessmentResult?
    @Published var recordedVideoURL: URL?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let model = DepressionModel()

    var score: Int { responses.reduce(0, +) }

    func complete(user: User?) async {
        isProcessing = true
        errorMessage = nil
        do {
            let aiScore = try model.predict(questionnaireScore: score, auFrames: auFrames)
            let auCSV = try CSVExportService.writeAUCSV(frames: auFrames, prefix: "mochan_au")
            let phqCSV = try CSVExportService.writeQuestionnaireCSV(type: .depression, responses: responses, prefix: "phq9")
            result = AssessmentResult(type: .depression, score: score, severity: .depression(score: score), aiScore: aiScore, videoURL: recordedVideoURL, auCSVURL: auCSV, questionnaireCSVURL: phqCSV)
            if let user { try? await UploadService.shared.useTrialAndUpload(user: user, result: result!) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}
