import SwiftUI

struct SahayQuestionnaireView: View {
    @ObservedObject var viewModel: SahayViewModel
    let onNext: () -> Void
    let onFinish: () -> Void

    @State private var isBengali = false

    private let englishLabels = [
        "Not at all",
        "Several days",
        "More than half",
        "Nearly every day"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Language Toggle
            Picker("Language", selection: $isBengali) {
                Text("English").tag(false)
                Text("বাংলা").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(GAD7.questions.count)")
                    .font(.caption.bold())
                    .foregroundColor(MochanTheme.sage)
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(GAD7.questions.count))
                    .tint(MochanTheme.purple)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(currentQuestionText)
                    .font(.title3.bold())
                    .foregroundColor(MochanTheme.sageDark)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { score in
                        Button {
                            viewModel.responses[viewModel.currentQuestion.id] = score
                        } label: {
                            HStack {
                                Text("\(score)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(MochanTheme.purple)
                                    .clipShape(Circle())
                                Text(answerLabel(for: score))
                                    .foregroundColor(MochanTheme.sageDark)
                                Spacer()
                                if viewModel.responses[viewModel.currentQuestion.id] == score {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MochanTheme.mild)
                                }
                            }
                            .padding(12)
                            .background(selectionBackground(score: score))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mochanCard()

            if viewModel.liveAIScore != nil {
                Text("AI analysis is active")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Button {
                viewModel.isLastQuestion ? onFinish() : onNext()
            } label: {
                Text(viewModel.isLastQuestion ? "Finish Assessment" : "Next")
            }
            .mochanButton(disabled: viewModel.isProcessing)
            .disabled(viewModel.isProcessing)

            if viewModel.isProcessing {
                ProgressView("Analyzing assessment...")
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(MochanTheme.severe)
            }
        }
    }

    private var currentQuestionText: String {
        guard isBengali else {
            return viewModel.currentQuestion.text
        }
        let index = viewModel.currentQuestionIndex
        guard index < BengaliTranslations.gad7Questions.count else {
            return viewModel.currentQuestion.text
        }
        return BengaliTranslations.gad7Questions[index]
    }

    private func answerLabel(for score: Int) -> String {
        guard isBengali else {
            return englishLabels[score]
        }
        guard score < BengaliTranslations.answerOptions.count else {
            return englishLabels[score]
        }
        return BengaliTranslations.answerOptions[score]
    }

    private func selectionBackground(score: Int) -> Color {
        viewModel.responses[viewModel.currentQuestion.id] == score ? MochanTheme.sageSoft.opacity(0.75) : Color.white
    }
}

// Optional: Keep QuestionnairePicker for reuse (with Bengali support if needed)
struct QuestionnairePicker: View {
    let question: QuestionnaireQuestion
    @Binding var selection: Int
    let isBengali: Bool

    private let englishLabels = ["Not at all", "Several days", "More than half", "Nearly every day"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isBengali ? bengaliQuestionText : question.text)
                .font(.subheadline.bold())
                .foregroundColor(MochanTheme.sageDark)
            Picker("Score", selection: $selection) {
                ForEach(0..<4) { score in
                    Text("\(score) - \(isBengali ? BengaliTranslations.answerOptions[score] : englishLabels[score])")
                        .tag(score)
                }
            }
            .pickerStyle(.segmented)
        }
        .mochanCard()
    }

    private var bengaliQuestionText: String {
        // This is a generic picker; we need to know the assessment type.
        // For simplicity, we'll just return the original text – but it's not used in the main flow.
        // If you use this picker elsewhere, you can pass the translated array.
        return question.text
    }
}
