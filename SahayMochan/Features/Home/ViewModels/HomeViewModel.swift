import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var anxietyTrials: TrialStatus?
    @Published var depressionTrials: TrialStatus?
    @Published var errorMessage: String?

    func refreshTrials(for user: User) async {
        do {
            anxietyTrials = try await APIClient.shared.request(.checkTrials(registrationID: user.registrationID, type: .anxiety))
            depressionTrials = try await APIClient.shared.request(.checkTrials(registrationID: user.registrationID, type: .depression))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
