import SwiftUI

struct PatientDetailView: View {
    let patient: ClinicianPatient

    var body: some View {
        List {
            Section("Patient") {
                row("Name", patient.name)
                row("Registration ID", patient.registrationID)
                row("Email", patient.email)
                row("Age", patient.age > 0 ? "\(patient.age)" : "--")
                row("Gender", patient.gender)
            }

            Section("Clinical Assessments") {
                NavigationLink("HAM-A Assessment") { HAMAAssessmentView(patient: patient) }
                NavigationLink("HDRS Assessment") { HDRSAssessmentView(patient: patient) }
            }
        }
        .navigationTitle(patient.name.isEmpty ? "Patient" : patient.name)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.isEmpty ? "--" : value)
                .foregroundColor(.secondary)
        }
    }
}
