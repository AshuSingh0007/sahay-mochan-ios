import SwiftUI

struct MochanResultView: View {
    let result: AssessmentResult

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ResultHeader(result: result)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Care Suggestions").font(.headline).foregroundColor(MochanTheme.sageDark)
                    Text("Use the wellness tools, keep a daily mood log, and contact a qualified professional if symptoms are severe or worsening.")
                        .foregroundColor(.secondary)
                }
                .mochanCard()
                Text("Generated files: \(result.auCSVURL.lastPathComponent), \(result.questionnaireCSVURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Mochan Result")
    }
}
