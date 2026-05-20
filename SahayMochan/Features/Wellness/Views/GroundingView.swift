import SwiftUI

struct GroundingView: View {
    @State private var answers = Array(repeating: "", count: 5)
    private let prompts = ["See - 5 things", "Touch - 4 things", "Hear - 3 things", "Smell - 2 things", "Taste - 1 thing"]

    var body: some View {
        Form {
            ForEach(prompts.indices, id: \.self) { index in
                Section(prompts[index]) { TextField("Write what you notice", text: $answers[index]) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Grounding")
    }
}
