import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var anxietyTrials: TrialCheckResponse?
    @Published var depressionTrials: TrialCheckResponse?
    @Published var errorMessage: String?

    func refreshTrials(for user: User) async {
        do {
            anxietyTrials = try await APIClient.shared.request(.checkTrials(registrationID: user.registrationID, type: .anxiety))
            depressionTrials = try await APIClient.shared.request(.checkTrials(registrationID: user.registrationID, type: .depression))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remainingTrials(for type: AssessmentType) -> Int {
        switch type {
        case .anxiety:
            return anxietyTrials?.remainingTrials(for: .anxiety) ?? 0
        case .depression:
            return depressionTrials?.remainingTrials(for: .depression) ?? 0
        }
    }

    func canTake(for type: AssessmentType) -> Bool {
        switch type {
        case .anxiety:
            return anxietyTrials?.canTake(for: .anxiety) ?? false
        case .depression:
            return depressionTrials?.canTake(for: .depression) ?? false
        }
    }

    func canProceed(user: User, type: AssessmentType) async -> Bool {
        do {
            let status: TrialCheckResponse = try await APIClient.shared.request(.checkTrials(registrationID: user.registrationID, type: type))
            if type == .anxiety {
                anxietyTrials = status
            } else {
                depressionTrials = status
            }
            return status.canTake(for: type)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
