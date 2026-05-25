import SwiftUI

struct SahayResultView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let result: AssessmentResult
    @ObservedObject var viewModel: SahayViewModel
    var onReturnHome: (() -> Void)? = nil

    private var questionnaireLevel: Severity { .anxiety(score: result.score) }
    private var aiLevel: Severity { .anxiety(score: Int((result.aiScore ?? Double(result.score)).rounded())) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                levelSummary
                recommendations
                uploadPanel
                returnHomeButton
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Sahay Result")
    }

    private var levelSummary: some View {
        VStack(spacing: 12) {
            Text("GAD-7 Anxiety Result")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)

            HStack(spacing: 12) {
                levelTile("Questionnaire Level", questionnaireLevel)
                levelTile("AI Analysis Level", aiLevel)
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

    private func levelTile(_ title: String, _ severity: Severity) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(severity.rawValue)
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(severity.color.opacity(0.18))
                .foregroundColor(severity.color)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(MochanTheme.purpleMist)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recommendationLines: [String] {
        switch questionnaireLevel {
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

    private var questionnaireLevel: Severity {
        result.type == .anxiety ? .anxiety(score: result.score) : .depression(score: result.score)
    }

    private var aiLevel: Severity {
        let score = Int((result.aiScore ?? Double(result.score)).rounded())
        return result.type == .anxiety ? .anxiety(score: score) : .depression(score: score)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(result.type.questionnaireName)
                .font(.headline)
            Text("Questionnaire Level: \(questionnaireLevel.rawValue)")
                .font(.headline)
                .foregroundColor(questionnaireLevel.color)
            Text("AI Analysis Level: \(aiLevel.rawValue)")
                .font(.headline)
                .foregroundColor(aiLevel.color)
        }
        .frame(maxWidth: .infinity)
        .mochanCard()
    }
}
