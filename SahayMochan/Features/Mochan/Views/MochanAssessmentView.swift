import SwiftUI

struct MochanAssessmentView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MochanViewModel()
    @StateObject private var recorder = VideoRecorderService()
    @State private var isCameraReady = false
    @State private var isAssessmentActive = false
    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MochanTheme.sageBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                if isAssessmentActive {
                    MochanQuestionnaireView(
                        viewModel: viewModel,
                        onNext: advance,
                        onFinish: finishAssessment
                    )
                } else {
                    introView
                }
            }
            .padding()

            if isAssessmentActive || recorder.isRecording {
                SahayCameraView(recorder: recorder)
                    .frame(width: 120, height: 160)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
        .navigationTitle("Mochan")
        .sheet(isPresented: $showResult) {
            if let result = viewModel.result {
                NavigationView {
                    MochanResultView(result: result, viewModel: viewModel) {
                        showResult = false
                        dismiss()
                    }
                }
            }
        }
        .task { await prepareCamera() }
        .onDisappear {
            recorder.frameHandler = nil
            recorder.stopSession()
        }
    }

    private var introView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundColor(MochanTheme.purple)
            Text("Mochan Depression Assessment")
                .font(.title2.bold())
                .foregroundColor(MochanTheme.sageDark)
            Text("Answer nine PHQ-9 questions while the front camera records facial cues for AI-assisted scoring.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await startAssessment() }
            } label: {
                Text(isCameraReady ? "Start Assessment" : "Preparing Camera...")
            }
            .mochanButton(disabled: !isCameraReady)
            .disabled(!isCameraReady)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(MochanTheme.severe)
                    .font(.footnote)
            }
        }
        .mochanCard()
    }

    private func prepareCamera() async {
        guard await recorder.requestPermissions() else {
            viewModel.errorMessage = "Camera permission is required for the assessment."
            return
        }

        do {
            try recorder.configureSession()
            recorder.frameHandler = { sampleBuffer in
                viewModel.processFrame(sampleBuffer)
            }
            recorder.startSession()
            isCameraReady = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func startAssessment() async {
        viewModel.reset()
        showResult = false
        recorder.frameHandler = { sampleBuffer in
            viewModel.processFrame(sampleBuffer)
        }

        do {
            try recorder.startRecording()
            isAssessmentActive = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func advance() {
        _ = viewModel.moveToNextQuestion()
    }

    private func finishAssessment() {
        Task {
            do {
                viewModel.recordedVideoURL = try await recorder.stopRecording()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }

            await viewModel.complete(user: auth.currentUser)
            isAssessmentActive = false
            showResult = viewModel.result != nil
        }
    }
}
