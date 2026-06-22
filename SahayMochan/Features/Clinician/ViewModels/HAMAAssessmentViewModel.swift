import Combine
import Foundation

@MainActor
final class HAMAAssessmentViewModel: ObservableObject {
    static let questions: [ClinicalQuestion] = [
        .init(
            id: 0,
            text: """
            Anxious mood
            Worries, anticipation of the worst, fearful anticipation, irritability.
            """,
            maxScore: 4
        ),
        .init(
            id: 1,
            text: """
            Tension
            Feelings of tension, fatigability, startle response, moved to tears easily, trembling, feelings of restlessness, inability to relax.
            """,
            maxScore: 4
        ),
        .init(
            id: 2,
            text: """
            Fears
            Of dark, of strangers, of being left alone, of animals, of traffic, of crowds.
            """,
            maxScore: 4
        ),
        .init(
            id: 3,
            text: """
            Insomnia
            Difficulty in falling asleep, broken sleep, unsatisfying sleep and fatigue on waking, dreams, nightmares, night terrors.
            """,
            maxScore: 4
        ),
        .init(
            id: 4,
            text: """
            Intellectual (cognitive)
            Difficulty in concentration, poor memory.
            """,
            maxScore: 4
        ),
        .init(
            id: 5,
            text: """
            Depressed mood
            Loss of interest, lack of pleasure in hobbies, depression, early waking, diurnal swing.
            """,
            maxScore: 4
        ),
        .init(
            id: 6,
            text: """
            Somatic (muscular)
            Pains and aches, twitching, stiffness, myoclonic jerks, grinding of teeth, unsteady voice, increased muscular tone.
            """,
            maxScore: 4
        ),
        .init(
            id: 7,
            text: """
            Somatic (sensory)
            Tinnitus, blurring of vision, hot and cold flushes, feelings of weakness, pricking sensation.
            """,
            maxScore: 4
        ),
        .init(
            id: 8,
            text: """
            Cardiovascular symptoms
            Tachycardia, palpitations, pain in chest, throbbing of vessels, fainting feelings, missing beat.
            """,
            maxScore: 4
        ),
        .init(
            id: 9,
            text: """
            Respiratory symptoms
            Pressure or constriction in chest, choking feelings, sighing, dyspnea.
            """,
            maxScore: 4
        ),
        .init(
            id: 10,
            text: """
            Gastrointestinal symptoms
            Difficulty in swallowing, wind abdominal pain, burning sensations, abdominal fullness, nausea, vomiting, borborygmi, looseness of bowels, loss of weight, constipation.
            """,
            maxScore: 4
        ),
        .init(
            id: 11,
            text: """
            Genitourinary symptoms
            Frequency of micturition, urgency of micturition, amenorrhea, menorrhagia, development of frigidity, premature ejaculation, loss of libido, impotence.
            """,
            maxScore: 4
        ),
        .init(
            id: 12,
            text: """
            Autonomic symptoms
            Dry mouth, flushing, pallor, tendency to sweat, giddiness, tension headache, raising of hair.
            """,
            maxScore: 4
        ),
        .init(
            id: 13,
            text: """
            Behavior at interview
            Fidgeting, restlessness or pacing, tremor of hands, furrowed brow, strained face, sighing or rapid respiration, facial pallor, swallowing, etc.
            """,
            maxScore: 4
        )
    ]   // ✅ Fixed: newline before next property

    @Published var scores = Array(repeating: 0, count: questions.count)
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var result: ClinicalAssessmentResponse?

    func submit(patient: ClinicianPatient, clinicianID: String) async {
        isSubmitting = true
        errorMessage = nil
        do {
            let body = ClinicalAssessmentRequest(
                patientID: patient.patientID,
                clinicianID: clinicianID,
                itemScores: scores
            )
            result = try await APIClient.shared.request(.hamaAssessment, body: body)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
