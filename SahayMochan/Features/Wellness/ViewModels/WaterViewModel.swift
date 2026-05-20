import Combine
import Foundation

@MainActor
final class WaterViewModel: ObservableObject {
    @Published var consumedML: Int = UserDefaults.standard.integer(forKey: "water_ml") { didSet { UserDefaults.standard.set(consumedML, forKey: "water_ml") } }
    let goalML = 2640
    var progress: Double { min(1, Double(consumedML) / Double(goalML)) }
    func add(_ amount: Int) { consumedML += amount }
    func reset() { consumedML = 0 }
}
