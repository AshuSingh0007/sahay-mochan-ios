import SwiftUI
import Combine

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var text = ""
    @State private var tags = ""

    var body: some View {
        List {
            Section("New Entry") {
                TextEditor(text: $text).frame(minHeight: 120)
                TextField("Tags, comma separated", text: $tags)
                Text("\(text.split(separator: " ").count) / \(viewModel.wordLimit) words").font(.caption).foregroundColor(.secondary)
                Button("Save") { viewModel.add(text: text, tags: tags); text = ""; tags = "" }.disabled(text.isEmpty)
            }
            Section("Entries") {
                ForEach(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.text)
                        Text(entry.tags.joined(separator: " #")).font(.caption).foregroundColor(MochanTheme.purple)
                    }
                }
                .onDelete(perform: viewModel.delete)
            }
        }
        .navigationTitle("Journal")
    }
}
