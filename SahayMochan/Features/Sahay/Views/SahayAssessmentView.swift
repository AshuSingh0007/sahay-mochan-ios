import SwiftUI

struct SahayAssessmentView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SahayViewModel()
    @StateObject private var recorder = VideoRecorderService()
    @State private var isCameraReady = false
    @State private var isAssessmentActive = false
    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MochanTheme.sageBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                if isAssessmentActive {
                    SahayQuestionnaireView(
                        viewModel: viewModel,
                        onNext: advance,
                        onFinish: finishAssessment
                    )
                    .padding(.top, 170)
                } else {
                    introView
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)   // ✅ Prevents overlap with tab bar

            if isAssessmentActive || recorder.isRecording {
                SahayCameraView(recorder: recorder)
                    .frame(width: 110, height: 150)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
        .navigationTitle("Sahay")
        .toolbar(.hidden, for: .tabBar)   // ✅ Hide tab bar during assessment
        .sheet(isPresented: $showResult) {
            if let result = viewModel.result {
                NavigationView {
                    SahayResultView(result: result, viewModel: viewModel) {
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
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44))
                .foregroundColor(MochanTheme.purple)
            Text("Sahay Anxiety Assessment")
                .font(.title2.bold())
                .foregroundColor(MochanTheme.sageDark)
            Text("Answer seven GAD-7 questions while the front camera records facial cues for AI-assisted scoring.")
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
            print("✅ Sahay recording started, isRecording = \(recorder.isRecording)")
            isAssessmentActive = true
        } catch {
            viewModel.errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func advance() {
        _ = viewModel.moveToNextQuestion()
    }

    private func finishAssessment() {
        Task {
            var videoURL: URL?
            var recordingError: Error?

            if recorder.isRecording {
                do {
                    videoURL = try await recorder.stopRecording()
                    print("✅ Sahay video recorded at: \(videoURL?.path ?? "nil")")

                    if let url = videoURL, FileManager.default.fileExists(atPath: url.path) {
                        print("✅ Video file exists at: \(url)")
                    } else {
                        print("❌ Video file missing after stopRecording!")
                        recordingError = NSError(domain: "VideoRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video file not saved"])
                        viewModel.errorMessage = "Video file was not saved. Please retake the assessment."
                    }
                } catch {
                    print("❌ Sahay stopRecording error: \(error)")
                    recordingError = error
                    viewModel.errorMessage = error.localizedDescription
                    if let lastURL = recorder.lastRecordedURL, FileManager.default.fileExists(atPath: lastURL.path) {
                        videoURL = lastURL
                        print("⚠️ Using lastRecordedURL: \(lastURL.path)")
                    }
                }
            } else {
                if let lastURL = recorder.lastRecordedURL, FileManager.default.fileExists(atPath: lastURL.path) {
                    videoURL = lastURL
                    print("⚠️ No active recording, using lastRecordedURL: \(lastURL.path)")
                } else {
                    print("❌ No active recording and no valid lastRecordedURL")
                    viewModel.errorMessage = "No recording was active. Please retake the assessment."
                }
            }

            if let videoURL {
                viewModel.setRecordedVideoURL(videoURL)
            } else {
                if viewModel.errorMessage == nil {
                    viewModel.errorMessage = "Video recording failed. Please retake assessment."
                }
            }

            await viewModel.complete(user: auth.currentUser)
            isAssessmentActive = false
            showResult = viewModel.result != nil
        }
    }
}
