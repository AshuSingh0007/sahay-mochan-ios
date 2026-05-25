import SwiftUI

struct SahayResultView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let result: AssessmentResult
    @ObservedObject var viewModel: SahayViewModel
    var onReturnHome: (() -> Void)? = nil

    private var aiScore: Double { result.aiScore ?? Double(result.score) }
    private var combinedScore: Int { Int(((Double(result.score) + aiScore) / 2.0).rounded()) }
    private var combinedSeverity: Severity { .anxiety(score: combinedScore) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreSummary
                recommendations

                AnxietyHeatmap(values: (0..<36).map { Double(($0 + combinedScore) % 10) / 10.0 })
                    .mochanCard()

                uploadPanel
                returnHomeButton

                Text("Generated files: \(result.auCSVURL.lastPathComponent), \(result.questionnaireCSVURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Sahay Result")
    }

    private var scoreSummary: some View {
        VStack(spacing: 12) {
            Text("GAD-7 Anxiety Result")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)

            HStack(spacing: 12) {
                scoreTile("Questionnaire", "\(result.score) / 21")
                scoreTile("AI score", "\(String(format: "%.1f", aiScore)) / 21")
            }

            VStack(spacing: 6) {
                Text("Combined score: \(combinedScore) / 21")
                    .font(.title3.bold())
                    .foregroundColor(MochanTheme.sageDark)
                Text(combinedSeverity.rawValue)
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(combinedSeverity.color.opacity(0.18))
                    .foregroundColor(combinedSeverity.color)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .mochanCard()
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)

            ForEach(recommendationLines, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MochanTheme.mild)
                    Text(line)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mochanCard()
    }

    private var uploadPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Assessment")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)

            if viewModel.isUploading {
                ProgressView(value: viewModel.uploadProgress)
                    .tint(MochanTheme.purple)
            }

            Button {
                Task { await viewModel.uploadResult(user: auth.currentUser) }
            } label: {
                Text(viewModel.isUploading ? "Uploading..." : "Upload to Server")
            }
            .mochanButton(disabled: viewModel.isUploading)
            .disabled(viewModel.isUploading)

            if let message = viewModel.uploadMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(MochanTheme.mild)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(MochanTheme.severe)
            }
        }
        .mochanCard()
    }

    private var returnHomeButton: some View {
        Button {
            if let onReturnHome {
                onReturnHome()
            } else {
                dismiss()
            }
        } label: {
            Text("Return Home")
        }
        .mochanButton()
    }

    private func scoreTile(_ title: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(MochanTheme.purpleMist)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recommendationLines: [String] {
        switch combinedSeverity {
        case .mild:
            return [
                "Continue daily check-ins, sleep tracking, and regular movement.",
                "Use breathing or grounding exercises when stress begins to rise."
            ]
        case .moderate:
            return [
                "Schedule time for structured relaxation and journaling this week.",
                "Consider speaking with a counselor or trusted support person."
            ]
        case .severe:
            return [
                "Reach out to a qualified mental health professional as soon as possible.",
                "If you feel unsafe or at risk of harm, contact local emergency support immediately."
            ]
        }
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
            if let aiScore = result.aiScore {
                Text("AI score: \(String(format: "%.1f", aiScore))")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .mochanCard()
    }
}
