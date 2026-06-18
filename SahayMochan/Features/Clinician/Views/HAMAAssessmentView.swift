import SwiftUI

struct HAMAAssessmentView: View {
    let patient: ClinicianPatient
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HAMAAssessmentViewModel()
    @State private var showResult = false

    var body: some View {
        NavigationStack {   // ✅ Use NavigationStack instead of NavigationView
            Form {
                Section("HAM-A") {
                    ForEach(HAMAAssessmentViewModel.questions) { question in
                        Picker(question.text, selection: $viewModel.scores[question.id]) {
                            ForEach(0...question.maxScore, id: \.self) { score in
                                Text("\(score)").tag(score)
                            }
                        }
                    }
                }

                Button(viewModel.isSubmitting ? "Submitting..." : "Submit") {
                    Task {
                        guard let clinicianID = auth.currentUser?.userID else {
                            viewModel.errorMessage = "Clinician ID not available."
                            return
                        }
                        await viewModel.submit(patient: patient, clinicianID: clinicianID)
                        showResult = viewModel.result != nil
                    }
                }
                .disabled(viewModel.isSubmitting)

                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(MochanTheme.severe)
                }
            }
            .navigationTitle("HAM-A")
            .navigationDestination(isPresented: $showResult) {
                if let result = viewModel.result {
                    ClinicalResultView(patient: patient, assessmentType: "ham-a", title: "HAM-A", maxScore: 56, result: result)
                }
            }
        }
    }
}
