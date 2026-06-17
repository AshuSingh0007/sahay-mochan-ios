import Combine
import Foundation

@MainActor
final class HDRSAssessmentViewModel: ObservableObject {
    static let questions: [ClinicalQuestion] = [
        .init(id: 0, text: "Depressed mood", maxScore: 4),
        .init(id: 1, text: "Feelings of guilt", maxScore: 4),
        .init(id: 2, text: "Suicide", maxScore: 4),
        .init(id: 3, text: "Insomnia early", maxScore: 2),
        .init(id: 4, text: "Insomnia middle", maxScore: 2),
        .init(id: 5, text: "Insomnia late", maxScore: 2),
        .init(id: 6, text: "Work and activities", maxScore: 4),
        .init(id: 7, text: "Retardation", maxScore: 4),
        .init(id: 8, text: "Agitation", maxScore: 4),
        .init(id: 9, text: "Anxiety psychic", maxScore: 4),
        .init(id: 10, text: "Anxiety somatic", maxScore: 4),
        .init(id: 11, text: "Somatic gastrointestinal", maxScore: 2),
        .init(id: 12, text: "Somatic general", maxScore: 2),
        .init(id: 13, text: "Genital symptoms", maxScore: 2),
        .init(id: 14, text: "Hypochondriasis", maxScore: 4),
        .init(id: 15, text: "Loss of weight", maxScore: 2),
        .init(id: 16, text: "Insight", maxScore: 2)
    ]

    @Published var scores = questions.map { _ in 0 }
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var result: ClinicalAssessmentResponse?

    func submit(patient: ClinicianPatient) async {
        isSubmitting = true
        errorMessage = nil
        do {
            let body = ClinicalAssessmentRequest(registrationID: patient.registrationID, scores: scores)
            result = try await APIClient.shared.request(.hdrsAssessment, body: body)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
