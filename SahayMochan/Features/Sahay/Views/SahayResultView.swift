import SwiftUI

struct SahayResultView: View {
    let result: AssessmentResult

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ResultHeader(result: result)
                AnxietyHeatmap(values: (0..<36).map { Double(($0 + result.score) % 10) / 10.0 })
                    .mochanCard()
                Text("Generated files: \(result.auCSVURL.lastPathComponent), \(result.questionnaireCSVURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Sahay Result")
    }
}

struct ResultHeader: View {
    let result: AssessmentResult

    var body: some View {
        VStack(spacing: 10) {
            Text(result.type.questionnaireName)
                .font(.headline)
            Text("\(result.score) / \(result.type.maxScore)")
                .font(.largeTitle.bold())
                .foregroundColor(MochanTheme.sageDark)
            Text(result.severity.rawValue)
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(result.severity.color.opacity(0.18))
                .foregroundColor(result.severity.color)
                .cornerRadius(8)
            if let aiScore = result.aiScore { Text("AI raw score: \(aiScore, specifier: "%.2f")").foregroundColor(.secondary) }
        }
        .frame(maxWidth: .infinity)
        .mochanCard()
    }
}
