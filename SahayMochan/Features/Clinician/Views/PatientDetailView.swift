import SwiftUI

struct PatientDetailView: View {
    let patient: ClinicianPatient

    @State private var latestGADScore: Int?
    @State private var latestPHQScore: Int?
    @State private var isLoadingSelf = false
    @State private var selfAssessmentError: String?

    var body: some View {
        List {
            Section("Patient") {
                row("Name", patient.name)
                row("Registration ID", patient.registrationID)
                row("Email", patient.email)
                row("Age", patient.age > 0 ? "\(patient.age)" : "--")
                // ✅ Show gender only if non‑empty
                if !patient.gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    row("Gender", patient.gender)
                }
            }

            Section("Latest Self Assessments") {
                if isLoadingSelf {
                    ProgressView()
                } else if let error = selfAssessmentError {
                    Text(error).foregroundColor(MochanTheme.severe)
                } else {
                    row("GAD-7", latestGADScore.map { "\($0)" } ?? "None")
                    row("PHQ-9", latestPHQScore.map { "\($0)" } ?? "None")
                }
            }

            Section("Latest Clinical Assessments") {
                row("HAM-A", patient.latestHamAScore.map { "\($0)" } ?? "None")
                row("HAM-D", patient.latestHDRSScore.map { "\($0)" } ?? "None")
            }

            Section("Clinical Assessments") {
                NavigationLink("HAM-A Assessment") { HAMAAssessmentView(patient: patient) }
                NavigationLink("HAM-D Assessment") { HDRSAssessmentView(patient: patient) }
            }
        }
        .navigationTitle(patient.name.isEmpty ? "Patient" : patient.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    Task { await fetchSelfAssessments() }
                }
            }
        }
        .task {
            await fetchSelfAssessments()
        }
        .refreshable {
            await fetchSelfAssessments()
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value.isEmpty ? "--" : value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private func fetchSelfAssessments() async {
        isLoadingSelf = true
        selfAssessmentError = nil

        do {
            let response: AssessmentHistoryResponse = try await APIClient.shared.request(.assessments(registrationID: patient.registrationID))
            let sorted = response.assessments.sorted { $0.createdAt > $1.createdAt }

            if let latestAnxiety = sorted.first(where: { $0.assessmentType == .anxiety }) {
                latestGADScore = latestAnxiety.questionnaireScore
            } else {
                latestGADScore = nil
            }

            if let latestDepression = sorted.first(where: { $0.assessmentType == .depression }) {
                latestPHQScore = latestDepression.questionnaireScore
            } else {
                latestPHQScore = nil
            }

        } catch {
            selfAssessmentError = error.localizedDescription
        }

        isLoadingSelf = false
    }
}
