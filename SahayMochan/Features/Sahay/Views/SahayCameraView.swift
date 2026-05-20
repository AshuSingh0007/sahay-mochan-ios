import SwiftUI
import Combine

struct SahayCameraView: View {
    @ObservedObject var viewModel: SahayViewModel
    @StateObject private var camera = CameraService()
    @StateObject private var recorder = VideoRecorderService()
    @State private var statusText = "Camera is ready for assessment recording."

    var body: some View {
        VStack(spacing: 18) {
            CameraPreviewPlaceholder()
            Text(statusText)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                    Task { await toggleRecording() }
                }
                .buttonStyle(.borderedProminent)
                NavigationLink("Continue to GAD-7") { SahayQuestionnaireView(viewModel: viewModel) }
                    .disabled(recorder.isRecording)
            }
            if let url = viewModel.recordedVideoURL {
                Text(url.lastPathComponent).font(.caption).foregroundColor(MochanTheme.sage)
            }
        }
        .padding()
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .task { await prepareRecorder() }
        .navigationTitle("Camera")
    }

    private func prepareRecorder() async {
        _ = await camera.requestAccess()
        guard await recorder.requestPermissions() else {
            statusText = "Camera or microphone permission is required to record assessment video."
            return
        }
        do {
            try recorder.configureSession()
            recorder.startSession()
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func toggleRecording() async {
        do {
            if recorder.isRecording {
                viewModel.recordedVideoURL = try await recorder.stopRecording()
                statusText = "Recording saved for upload."
            } else {
                try recorder.startRecording()
                statusText = "Recording in progress."
            }
        } catch {
            statusText = error.localizedDescription
        }
    }
}
