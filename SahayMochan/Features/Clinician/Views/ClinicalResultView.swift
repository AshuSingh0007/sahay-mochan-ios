import SwiftUI

struct ClinicalResultView: View {
    @Environment(\.dismiss) private var dismiss
    let patient: ClinicianPatient
    let assessmentType: String
    let title: String
    let maxScore: Int
    let result: ClinicalAssessmentResponse

    @State private var selectedSeverity: String
    @State private var latestGAD: Severity?
    @State private var latestPHQ: Severity?
    @State private var isSaving = false
    @State private var message: String?

    private let severityOptions = ["Minimal", "Mild", "Moderate", "Moderately Severe", "Severe"]

    init(patient: ClinicianPatient, assessmentType: String, title: String, maxScore: Int, result: ClinicalAssessmentResponse) {
        self.patient = patient
        self.assessmentType = assessmentType
        self.title = title
        self.maxScore = maxScore
        self.result = result
        _selectedSeverity = State(initialValue: result.severity)
    }

    var body: some View {
        List {
            Section(title) {
                row("Total", "\(result.totalScore) / \(maxScore)")
                row("Backend Severity", result.severity)
                Picker("Severity", selection: $selectedSeverity) {
                    ForEach(severityOptions, id: \.self) { severity in
                        Text(severity).tag(severity)
                    }
                }
            }

            Section("Latest Self Assessments") {
                row("GAD-7", latestGAD?.rawValue ?? "N/A")
                row("PHQ-9", latestPHQ?.rawValue ?? "N/A")
            }

            Button(isSaving ? "Saving..." : "Save Severity") {
                Task { await saveSeverity() }
            }
            .disabled(isSaving)

            if let message {
                Text(message).foregroundColor(MochanTheme.mild)
            }
        }
        .navigationTitle("Result")
        .task { await loadLatestSelfAssessments() }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }

    private func saveSeverity() async {
        isSaving = true
        do {
            // ✅ assessmentID is now a String – pass directly
            let _: APIMessageResponse = try await APIClient.shared.request(
                .severityDirect(
                    assessmentType: assessmentType,
                    assessmentID: result.assessmentID,   // ← String, no conversion needed
                    severity: selectedSeverity
                ),
                body: Optional<String>.none
            )
            message = "Severity saved."
            dismiss()
        } catch {
            message = error.localizedDescription
        }
        isSaving = false
    }

    private func loadLatestSelfAssessments() async {
        do {
            let response: AssessmentHistoryResponse = try await APIClient.shared.request(.assessments(registrationID: patient.registrationID))
            let sorted = response.assessments.sorted { $0.createdAt > $1.createdAt }
            if let gad = sorted.first(where: { $0.assessmentType == .anxiety }) {
                latestGAD = .anxiety(score: gad.questionnaireScore)
            }
            if let phq = sorted.first(where: { $0.assessmentType == .depression }) {
                latestPHQ = .depression(score: phq.questionnaireScore)
            }
        } catch {
            latestGAD = nil
            latestPHQ = nil
        }
    }
}
