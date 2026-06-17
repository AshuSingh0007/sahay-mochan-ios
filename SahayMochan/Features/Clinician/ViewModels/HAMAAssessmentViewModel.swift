import Combine
import Foundation

struct ClinicalQuestion: Identifiable, Equatable {
    let id: Int
    let text: String
    let maxScore: Int
}

@MainActor
final class HAMAAssessmentViewModel: ObservableObject {
    static let questions: [ClinicalQuestion] = [
        .init(id: 0, text: "Anxious mood", maxScore: 4),
        .init(id: 1, text: "Tension", maxScore: 4),
        .init(id: 2, text: "Fears", maxScore: 4),
        .init(id: 3, text: "Insomnia", maxScore: 4),
        .init(id: 4, text: "Intellectual", maxScore: 4),
        .init(id: 5, text: "Depressed mood", maxScore: 4),
        .init(id: 6, text: "Somatic muscular", maxScore: 4),
        .init(id: 7, text: "Somatic sensory", maxScore: 4),
        .init(id: 8, text: "Cardiovascular symptoms", maxScore: 4),
        .init(id: 9, text: "Respiratory symptoms", maxScore: 4),
        .init(id: 10, text: "Gastrointestinal symptoms", maxScore: 4),
        .init(id: 11, text: "Genitourinary symptoms", maxScore: 4),
        .init(id: 12, text: "Autonomic symptoms", maxScore: 4),
        .init(id: 13, text: "Behavior at interview", maxScore: 4)
    ]

    @Published var scores = Array(repeating: 0, count: questions.count)
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var result: ClinicalAssessmentResponse?

    func submit(patient: ClinicianPatient) async {
        isSubmitting = true
        errorMessage = nil
        do {
            let body = ClinicalAssessmentRequest(registrationID: patient.registrationID, scores: scores)
            result = try await APIClient.shared.request(.hamaAssessment, body: body)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

struct ClinicalAssessmentRequest: Codable {
    let registrationID: String
    let scores: [Int]

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case scores
    }
}
