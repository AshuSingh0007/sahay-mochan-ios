import SwiftUI

struct MochanResultView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let result: AssessmentResult
    @ObservedObject var viewModel: MochanViewModel
    var onReturnHome: (() -> Void)? = nil

    private var aiScore: Double { result.aiScore ?? Double(result.score) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreSummary
                careSuggestions
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
        .navigationTitle("Mochan Result")
    }

    private var scoreSummary: some View {
        VStack(spacing: 12) {
            Text("PHQ-9 Depression Result")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)

            HStack(spacing: 12) {
                scoreTile("Questionnaire", "\(result.score) / 27")
                scoreTile("AI score", "\(String(format: "%.1f", aiScore)) / 27")
            }

            Text(result.severity.rawValue)
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(result.severity.color.opacity(0.18))
                .foregroundColor(result.severity.color)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .mochanCard()
    }

    private var careSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Care Suggestions")
                .font(.headline)
                .foregroundColor(MochanTheme.sageDark)
            Text("Use the wellness tools, keep a daily mood log, and contact a qualified professional if symptoms are severe or worsening.")
                .foregroundColor(.secondary)
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
}
