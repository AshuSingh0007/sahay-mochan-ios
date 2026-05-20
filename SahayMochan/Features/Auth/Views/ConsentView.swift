import SwiftUI

struct ConsentView: View {
    @Environment(\.dismiss) private var dismiss
    let onAccept: () -> Void
    @State private var acceptedDataUse = false
    @State private var acceptedRecording = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Consent")
                    .font(.title.bold())
                    .foregroundColor(MochanTheme.sageDark)
                Text("Assessments may record video and derive facial action-unit signals. Results are screening support only and not a clinical diagnosis.")
                    .foregroundColor(.secondary)
                Toggle("I consent to assessment data processing", isOn: $acceptedDataUse)
                Toggle("I consent to camera and microphone recording during assessments", isOn: $acceptedRecording)
                Spacer()
                Button("Continue") { onAccept() }
                    .mochanButton(disabled: !acceptedDataUse || !acceptedRecording)
                    .disabled(!acceptedDataUse || !acceptedRecording)
            }
            .padding()
            .background(MochanTheme.sageBackground.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
