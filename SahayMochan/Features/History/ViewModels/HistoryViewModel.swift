import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [AssessmentRecord] = []
    @Published var totalAssessments = 0
    @Published var studentID = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(registrationID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: AssessmentHistoryResponse = try await APIClient.shared.request(.assessments(registrationID: registrationID))
            records = response.assessments.sorted { $0.createdAt > $1.createdAt }
            totalAssessments = response.totalAssessments
            studentID = response.studentID
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func questionnaireLevel(for record: AssessmentRecord) -> Severity {
        let score = record.gad7Score ?? record.phqScore ?? record.questionnaireScore
        return severity(for: score, type: record.assessmentType)
    }

    func aiLevel(for record: AssessmentRecord) -> Severity {
        let score = Int((record.assessmentScore ?? Double(record.questionnaireScore)).rounded())
        return severity(for: score, type: record.assessmentType)
    }

    func delete(_ record: AssessmentRecord, registrationID: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteAssessment(id: record.id))
            await load(registrationID: registrationID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAll(registrationID: String) async {
        do {
            let _: EmptyResponse = try await APIClient.shared.request(.deleteAll(registrationID: registrationID))
            records.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func severity(for score: Int, type: AssessmentType) -> Severity {
        switch type {
        case .anxiety:
            return .anxiety(score: score)
        case .depression:
            return .depression(score: score)
        }
    }
}
