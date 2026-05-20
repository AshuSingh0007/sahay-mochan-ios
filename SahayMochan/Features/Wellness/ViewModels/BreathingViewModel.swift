import Combine
import Foundation

@MainActor
final class BreathingViewModel: ObservableObject {
    enum Phase: String { case inhale = "Inhale", hold = "Hold", exhale = "Exhale" }
    @Published var phase: Phase = .inhale
    @Published var secondsRemaining = 4
    @Published var isRunning = false
    private var task: Task<Void, Never>?

    func start() {
        isRunning = true
        task?.cancel()
        task = Task { await runCycle() }
    }

    func stop() {
        task?.cancel()
        isRunning = false
        phase = .inhale
        secondsRemaining = 4
    }

    private func runCycle() async {
        let pattern: [(Phase, Int)] = [(.inhale, 4), (.hold, 7), (.exhale, 8)]
        while !Task.isCancelled {
            for step in pattern {
                phase = step.0
                for second in stride(from: step.1, through: 1, by: -1) {
                    secondsRemaining = second
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }
}
