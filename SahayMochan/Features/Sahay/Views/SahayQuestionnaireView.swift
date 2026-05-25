import SwiftUI

struct SahayQuestionnaireView: View {
    @ObservedObject var viewModel: SahayViewModel
    let onNext: () -> Void
    let onFinish: () -> Void

    private let labels = [
        "Not at all",
        "Several days",
        "More than half",
        "Nearly every day"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(GAD7.questions.count)")
                    .font(.caption.bold())
                    .foregroundColor(MochanTheme.sage)
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(GAD7.questions.count))
                    .tint(MochanTheme.purple)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.currentQuestion.text)
                    .font(.title3.bold())
                    .foregroundColor(MochanTheme.sageDark)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(0..<labels.count, id: \.self) { score in
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
                                Text(labels[score])
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

            if let aiScore = viewModel.liveAIScore {
                Text("Live AI score: \(aiScore, specifier: "%.1f") / 21")
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

    private func selectionBackground(score: Int) -> Color {
        viewModel.responses[viewModel.currentQuestion.id] == score ? MochanTheme.sageSoft.opacity(0.75) : Color.white
    }
}

struct QuestionnairePicker: View {
    let question: QuestionnaireQuestion
    @Binding var selection: Int
    private let labels = ["Not at all", "Several days", "More than half", "Nearly every day"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.text)
                .font(.subheadline.bold())
                .foregroundColor(MochanTheme.sageDark)
            Picker("Score", selection: $selection) {
                ForEach(0..<4) { score in
                    Text("\(score) - \(labels[score])").tag(score)
                }
            }
            .pickerStyle(.segmented)
        }
        .mochanCard()
    }
}
