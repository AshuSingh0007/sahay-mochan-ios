import Combine
import Foundation

@MainActor
final class HDRSAssessmentViewModel: ObservableObject {
    static let questions: [ClinicalQuestion] = [
        .init(
            id: 0,
            text: """
            DEPRESSED MOOD (sadness, hopeless, helpless, worthless)
            0 – Absent
            1 – These feeling states indicated only on questioning
            2 – These feeling states spontaneously reported verbally
            3 – Communicates feeling states non‑verbally (facial expression, posture, voice, tendency to weep)
            4 – Patient reports virtually only these feeling states in spontaneous verbal and non‑verbal communication
            """,
            maxScore: 4
        ),
        .init(
            id: 1,
            text: """
            FEELINGS OF GUILT
            0 – Absent
            1 – Self reproach, feels he/she has let people down
            2 – Ideas of guilt or rumination over past errors or sinful deeds
            3 – Present illness is a punishment. Delusions of guilt
            4 – Hears accusatory or denunciatory voices and/or experiences threatening visual hallucination
            """,
            maxScore: 4
        ),
        .init(
            id: 2,
            text: """
            SUICIDE
            0 – Absent
            1 – Feels life is not worth living
            2 – Wishes he/she were dead or any thoughts of possible death to self
            3 – Ideas or gestures of suicide
            4 – Attempts at suicide (any serious attempt rate 4)
            """,
            maxScore: 4
        ),
        .init(
            id: 3,
            text: """
            INSOMNIA: EARLY IN THE NIGHT
            0 – No difficulty falling asleep
            1 – Complains of occasional difficulty falling asleep (> ½ hour)
            2 – Complains of nightly difficulty falling asleep
            """,
            maxScore: 2
        ),
        .init(
            id: 4,
            text: """
            INSOMNIA: MIDDLE OF THE NIGHT
            0 – No difficulty
            1 – Patient complains of being restless and disturbed during the night
            2 – Waking during the night – any getting out of bed rates 2 (except for voiding)
            """,
            maxScore: 2
        ),
        .init(
            id: 5,
            text: """
            INSOMNIA: EARLY HOURS OF THE MORNING
            0 – No difficulty
            1 – Waking in early hours of the morning but goes back to sleep
            2 – Unable to fall asleep again if he/she gets out of bed
            """,
            maxScore: 2
        ),
        .init(
            id: 6,
            text: """
            WORK AND ACTIVITIES
            0 – No difficulty
            1 – Thoughts and feelings of incapacity, fatigue or weakness related to activities, work or hobbies
            2 – Loss of interest in activity, hobbies or work (feels he/she has to push self)
            3 – Decrease in actual time spent in activities or productivity (<3 hours/day excluding routine chores)
            4 – Stopped working because of present illness, or engages in no activities except routine chores
            """,
            maxScore: 4
        ),
        .init(
            id: 7,
            text: """
            RETARDATION (slowness of thought and speech, impaired concentration, decreased motor activity)
            0 – Normal speech and thought
            1 – Slight retardation during the interview
            2 – Obvious retardation during the interview
            3 – Interview difficult
            4 – Complete stupor
            """,
            maxScore: 4
        ),
        .init(
            id: 8,
            text: """
            AGITATION
            0 – None
            1 – Fidgetiness
            2 – Playing with hands, hair, etc.
            3 – Moving about, can’t sit still
            4 – Hand wringing, nail biting, hair‑pulling, biting of lips
            """,
            maxScore: 4
        ),
        .init(
            id: 9,
            text: """
            ANXIETY PSYCHIC
            0 – No difficulty
            1 – Subjective tension and irritability
            2 – Worrying about minor matters
            3 – Apprehensive attitude apparent in face or speech
            4 – Fears expressed without questioning
            """,
            maxScore: 4
        ),
        .init(
            id: 10,
            text: """
            ANXIETY SOMATIC (physiological concomitants: dry mouth, wind, indigestion, diarrhea, cramps, belching, palpitations, headaches, hyperventilation, sighing, urinary frequency, sweating)
            0 – Absent
            1 – Mild
            2 – Moderate
            3 – Severe
            4 – Incapacitating
            """,
            maxScore: 4
        ),
        .init(
            id: 11,
            text: """
            SOMATIC SYMPTOMS GASTRO‑INTESTINAL
            0 – None
            1 – Loss of appetite but eating without staff encouragement. Heavy feelings in abdomen.
            2 – Difficulty eating without staff urging. Requests or requires laxatives or medication for bowel or gastro‑intestinal symptoms
            """,
            maxScore: 2
        ),
        .init(
            id: 12,
            text: """
            GENERAL SOMATIC SYMPTOMS
            0 – None
            1 – Heaviness in limbs, back or head. Backaches, headaches, muscle aches. Loss of energy and fatigability.
            2 – Any clear‑cut symptom rates 2
            """,
            maxScore: 2
        ),
        .init(
            id: 13,
            text: """
            GENITAL SYMPTOMS (loss of libido, menstrual disturbances)
            0 – Absent
            1 – Mild
            2 – Severe
            """,
            maxScore: 2
        ),
        .init(
            id: 14,
            text: """
            HYPOCHONDRIASIS
            0 – Not present
            1 – Self‑absorption (bodily)
            2 – Preoccupation with health
            3 – Frequent complaints, requests for help, etc.
            4 – Hypochondriacal delusions
            """,
            maxScore: 4
        ),
        .init(
            id: 15,
            text: """
            LOSS OF WEIGHT (rate either a or b)
            a) According to patient:
               0 – No weight loss
               1 – Probable weight loss associated with present illness
               2 – Definite weight loss
            b) According to weekly measurements:
               0 – Less than 1 lb weight loss in week
               1 – Greater than 1 lb weight loss in week
               2 – Greater than 2 lb weight loss in week
            """,
            maxScore: 2
        ),
        .init(
            id: 16,
            text: """
            INSIGHT
            0 – Acknowledges being depressed and ill
            1 – Acknowledges illness but attributes cause to bad food, climate, overwork, virus, need for rest, etc.
            2 – Denies being ill at all
            """,
            maxScore: 2
        )
    ]

    @Published var scores = questions.map { _ in 0 }
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var result: ClinicalAssessmentResponse?

    func submit(patient: ClinicianPatient, clinicianID: String) async {
        isSubmitting = true
        errorMessage = nil
        do {
            let body = ClinicalAssessmentRequest(
                patientID: patient.patientID,   // ✅ UUID, not registration_id
                clinicianID: clinicianID,
                itemScores: scores
            )
            result = try await APIClient.shared.request(.hdrsAssessment, body: body)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
