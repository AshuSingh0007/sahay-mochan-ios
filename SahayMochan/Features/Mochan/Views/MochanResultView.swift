import SwiftUI

struct MochanResultView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    let result: AssessmentResult
    @ObservedObject var viewModel: MochanViewModel
    var onReturnHome: (() -> Void)? = nil

    @State private var pdfURL: URL?
    @State private var showShare = false

    private var questionnaireLevel: Severity { .depression(score: result.score) }
    private var aiLevel: Severity { .depression(score: Int((result.aiScore ?? Double(result.score)).rounded())) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                levelSummary
                careSuggestions
                uploadPanel
                downloadPDFButton
                returnHomeButton
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Mochan Result")
        .sheet(isPresented: $showShare) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private var levelSummary: some View {
        VStack(spacing: 12) {
            Text("PHQ-9 Depression Result")
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

    private var downloadPDFButton: some View {
        Button("Download PDF") {
            guard let user = auth.currentUser else { return }
            if let url = PDFGenerator.generatePDF(
                for: result,
                user: user,
                recommendations: recommendationLines
            ) {
                pdfURL = url
                showShare = true
            }
        }
        .mochanButton()
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
