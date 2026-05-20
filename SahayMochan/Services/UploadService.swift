import Foundation

final class UploadService {
    static let shared = UploadService()

    func useTrialAndUpload(user: User, result: AssessmentResult) async throws {
        let trialBody = ["registration_id": user.registrationID, "assessment_type": result.type.rawValue]
        let _: APIMessageResponse = try await APIClient.shared.request(.useTrial, body: trialBody)
        _ = try await upload(user: user, result: result)
    }

    func upload(user: User, result: AssessmentResult) async throws -> APIMessageResponse {
        var fields: [String: String] = [
            "anonymous_id": user.anonymousID,
            "registration_id": user.registrationID,
            "age": "\(user.age)",
            "assessment_type": result.type.rawValue,
            "email": user.email
        ]
        if let aiScore = result.aiScore { fields["ai_raw_score"] = String(aiScore) }
        var files = [
            MultipartFile(fieldName: "au_csv", fileName: result.auCSVURL.lastPathComponent, mimeType: "text/csv", url: result.auCSVURL),
            MultipartFile(fieldName: result.type == .anxiety ? "gad7_csv" : "phq_csv", fileName: result.questionnaireCSVURL.lastPathComponent, mimeType: "text/csv", url: result.questionnaireCSVURL)
        ]
        if let videoURL = result.videoURL {
            files.append(MultipartFile(fieldName: "video", fileName: videoURL.lastPathComponent, mimeType: "video/mp4", url: videoURL))
        }
        return try await APIClient.shared.uploadMultipart(endpoint: .uploadAssessment, fields: fields, files: files)
    }
}

enum CSVExportService {
    static func writeAUCSV(frames: [AUFrame], prefix: String) throws -> URL {
        var rows = [["timestamp"] + (1...12).map { "au_\($0)" }]
        rows += frames.map { [String($0.timestamp)] + $0.values.map { String($0) } }
        return try FileManager.default.writeCSV(named: "\(prefix)_\(Int(Date().timeIntervalSince1970)).csv", rows: rows)
    }

    static func writeQuestionnaireCSV(type: AssessmentType, responses: [Int], prefix: String) throws -> URL {
        var rows = [["assessment_type", "question", "score"]]
        rows += responses.enumerated().map { [type.rawValue, String($0.offset + 1), String($0.element)] }
        return try FileManager.default.writeCSV(named: "\(prefix)_\(Int(Date().timeIntervalSince1970)).csv", rows: rows)
    }
}
