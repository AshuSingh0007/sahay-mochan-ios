import SwiftUI
import Combine

struct SahayQuestionnaireView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var viewModel: SahayViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(GAD7.questions) { question in
                    QuestionnairePicker(question: question, selection: $viewModel.responses[question.id])
                }
                Button { Task { await viewModel.complete(user: auth.currentUser) } } label: {
                    Text(viewModel.isProcessing ? "Processing..." : "See Result")
                }
                .mochanButton(disabled: viewModel.isProcessing)
                .disabled(viewModel.isProcessing)
                if let result = viewModel.result { NavigationLink("Open Result", destination: SahayResultView(result: result)).mochanButton() }
                if let error = viewModel.errorMessage { Text(error).foregroundColor(MochanTheme.severe) }
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("GAD-7")
    }
}

struct QuestionnairePicker: View {
    let question: QuestionnaireQuestion
    @Binding var selection: Int
    private let labels = ["Not at all", "Several days", "More than half", "Nearly every day"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.text).font(.subheadline.bold()).foregroundColor(MochanTheme.sageDark)
            Picker("Score", selection: $selection) {
                ForEach(0..<4) { Text("\($0) - \(labels[$0])").tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .mochanCard()
    }
}
