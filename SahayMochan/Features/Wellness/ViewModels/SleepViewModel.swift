import Combine
import Foundation

struct SleepLog: Codable, Identifiable {
    let id: UUID
    let hours: Double
    let quality: Int
    let date: Date
}

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var logs: [SleepLog] = [] { didSet { save() } }
    private let key = "sleep_logs"
    init() { load() }
    func add(hours: Double, quality: Int) { logs.insert(SleepLog(id: UUID(), hours: hours, quality: quality, date: Date()), at: 0) }
    var week: [SleepLog] { Array(logs.prefix(7)) }
    private func load() { logs = (try? JSONDecoder().decode([SleepLog].self, from: UserDefaults.standard.data(forKey: key) ?? Data())) ?? [] }
    private func save() { if let data = try? JSONEncoder().encode(logs) { UserDefaults.standard.set(data, forKey: key) } }
}
