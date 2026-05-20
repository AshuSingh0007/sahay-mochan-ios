import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [AssessmentRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(registrationID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            records = try await APIClient.shared.request(.assessments(registrationID: registrationID))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ record: AssessmentRecord, registrationID: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteAssessment(id: record.id))
            await load(registrationID: registrationID)
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteAll(registrationID: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteAll(registrationID: registrationID))
            records.removeAll()
        } catch { errorMessage = error.localizedDescription }
    }
}
