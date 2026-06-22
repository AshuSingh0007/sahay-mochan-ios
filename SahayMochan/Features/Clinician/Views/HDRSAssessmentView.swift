import SwiftUI

struct HDRSAssessmentView: View {
    let patient: ClinicianPatient
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HDRSAssessmentViewModel()
    @State private var showResult = false
    @State private var currentIndex = 0

    private var currentQuestion: ClinicalQuestion {
        HDRSAssessmentViewModel.questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex == HDRSAssessmentViewModel.questions.count - 1
    }

    private var isFirstQuestion: Bool {
        currentIndex == 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress header
                HStack {
                    Text("Question \(currentIndex + 1) of \(HDRSAssessmentViewModel.questions.count)")
                        .font(.caption.bold())
                        .foregroundColor(MochanTheme.sage)
                    Spacer()
                    Text("Score: \(viewModel.scores[currentIndex]) / \(currentQuestion.maxScore)")
                        .font(.caption.bold())
                        .foregroundColor(MochanTheme.purple)
                }
                .padding(.horizontal)

                ProgressView(value: Double(currentIndex + 1), total: Double(HDRSAssessmentViewModel.questions.count))
                    .tint(MochanTheme.purple)
                    .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Question text (full description)
                        Text(currentQuestion.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Score picker
                        Picker("Score", selection: $viewModel.scores[currentIndex]) {
                            ForEach(0...currentQuestion.maxScore, id: \.self) { score in
                                Text("\(score)").tag(score)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.white.opacity(0.94))
                    .cornerRadius(12)
                    .shadow(color: MochanTheme.sageDark.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }

                // Navigation buttons
                HStack(spacing: 12) {
                    if !isFirstQuestion {
                        Button("Previous") {
                            withAnimation { currentIndex -= 1 }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if isLastQuestion {
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
                        .mochanButton(disabled: viewModel.isSubmitting)
                    } else {
                        Button("Next") {
                            withAnimation { currentIndex += 1 }
                        }
                        .mochanButton()
                    }
                }
                .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(MochanTheme.severe)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(MochanTheme.sageBackground.ignoresSafeArea())
            .navigationTitle("HAM-D")
            .navigationDestination(isPresented: $showResult) {
                if let result = viewModel.result {
                    ClinicalResultView(patient: patient, assessmentType: "ham-d", title: "HAM-D", maxScore: 52, result: result)
                }
            }
        }
    }
}
