import SwiftUI
import Combine

struct MochanQuestionnaireView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var viewModel: MochanViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(PHQ9.questions) { question in
                    QuestionnairePicker(question: question, selection: $viewModel.responses[question.id])
                }
                Button { Task { await viewModel.complete(user: auth.currentUser) } } label: {
                    Text(viewModel.isProcessing ? "Processing..." : "See Result")
                }
                .mochanButton(disabled: viewModel.isProcessing)
                .disabled(viewModel.isProcessing)
                if let result = viewModel.result { NavigationLink("Open Result", destination: MochanResultView(result: result)).mochanButton() }
                if let error = viewModel.errorMessage { Text(error).foregroundColor(MochanTheme.severe) }
            }
            .padding()
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("PHQ-9")
    }
}
