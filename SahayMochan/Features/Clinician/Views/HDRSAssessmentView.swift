import SwiftUI

struct HDRSAssessmentView: View {
    let patient: ClinicianPatient
    @StateObject private var viewModel = HDRSAssessmentViewModel()
    @State private var showResult = false

    var body: some View {
        Form {
            Section("HAM-D") {
                ForEach(HDRSAssessmentViewModel.questions) { question in
                    Picker(question.text, selection: $viewModel.scores[question.id]) {
                        ForEach(0...question.maxScore, id: \.self) { score in
                            Text("\(score)").tag(score)
                        }
                    }
                }
            }

            Button(viewModel.isSubmitting ? "Submitting..." : "Submit") {
                Task {
                    await viewModel.submit(patient: patient)
                    showResult = viewModel.result != nil
                }
            }
            .disabled(viewModel.isSubmitting)

            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(MochanTheme.severe)
            }
        }
        .navigationTitle("HAM-D")
        .navigationDestination(isPresented: $showResult) {
            if let result = viewModel.result {
                ClinicalResultView(patient: patient, assessmentType: "ham-d", title: "HAM-D", maxScore: 52, result: result)
            }
        }
    }
}
