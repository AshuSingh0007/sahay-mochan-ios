import Combine
import Foundation

@MainActor
final class SahayViewModel: ObservableObject {
    @Published var responses = Array(repeating: 0, count: GAD7.questions.count)
    @Published var auFrames: [AUFrame] = FaceLandmarkerService.sampleFrames()
    @Published var result: AssessmentResult?
    @Published var recordedVideoURL: URL?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let model = AnxietyModel()

    var score: Int { responses.reduce(0, +) }

    func complete(user: User?) async {
        isProcessing = true
        errorMessage = nil
        do {
            let aiScore = try model.predict(questionnaireScore: score, auFrames: auFrames)
            let auCSV = try CSVExportService.writeAUCSV(frames: auFrames, prefix: "sahay_au")
            let gadCSV = try CSVExportService.writeQuestionnaireCSV(type: .anxiety, responses: responses, prefix: "gad7")
            result = AssessmentResult(type: .anxiety, score: score, severity: .anxiety(score: score), aiScore: aiScore, videoURL: recordedVideoURL, auCSVURL: auCSV, questionnaireCSVURL: gadCSV)
            if let user { try? await UploadService.shared.useTrialAndUpload(user: user, result: result!) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}
