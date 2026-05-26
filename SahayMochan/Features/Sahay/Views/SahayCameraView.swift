import SwiftUI

struct SahayCameraView: View {
    @ObservedObject var recorder: VideoRecorderService

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // The camera preview uses the session from the recorder.
            // It automatically updates when the session becomes active.
            CameraPreviewView(session: recorder.session)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(MochanTheme.sage.opacity(0.5), lineWidth: 1)
                )

            // Recording indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(recorder.isRecording ? MochanTheme.severe : MochanTheme.sage)
                    .frame(width: 7, height: 7)
                Text(recorder.isRecording ? "REC" : "CAM")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
            .padding(6)
        }
        .background(MochanTheme.sageDark.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: MochanTheme.sageDark.opacity(0.16), radius: 10, x: 0, y: 6)
        .accessibilityLabel("Front camera preview")
    }
}
