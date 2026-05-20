import Combine
import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let tags: [String]
    let createdAt: Date
}

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = [] { didSet { save() } }
    private let key = "journal_entries"
    let wordLimit = 300

    init() { load() }

    func add(text: String, tags: String) {
        let words = text.split(separator: " ").prefix(wordLimit).joined(separator: " ")
        let entry = JournalEntry(id: UUID(), text: words, tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }, createdAt: Date())
        entries.insert(entry, at: 0)
    }

    func delete(at offsets: IndexSet) { for index in offsets.sorted(by: >) { entries.remove(at: index) } }

    private func load() { entries = (try? JSONDecoder().decode([JournalEntry].self, from: UserDefaults.standard.data(forKey: key) ?? Data())) ?? [] }
    private func save() { if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: key) } }
}
