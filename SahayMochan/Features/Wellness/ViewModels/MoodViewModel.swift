import Combine
import Foundation

struct MoodLog: Codable, Identifiable {
    let id: UUID
    let emoji: String
    let happiness: Double
    let energy: Double
    let date: Date
}

@MainActor
final class MoodViewModel: ObservableObject {
    @Published var logs: [MoodLog] = [] { didSet { save() } }
    private let key = "mood_logs"
    init() { load() }
    func add(emoji: String, happiness: Double, energy: Double) { logs.insert(MoodLog(id: UUID(), emoji: emoji, happiness: happiness, energy: energy, date: Date()), at: 0) }
    var recent: [MoodLog] { Array(logs.prefix(30)) }
    private func load() { logs = (try? JSONDecoder().decode([MoodLog].self, from: UserDefaults.standard.data(forKey: key) ?? Data())) ?? [] }
    private func save() { if let data = try? JSONEncoder().encode(logs) { UserDefaults.standard.set(data, forKey: key) } }
}
