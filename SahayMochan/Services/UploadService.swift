import Foundation

extension Notification.Name {
    static let assessmentDidUpload = Notification.Name("assessmentDidUpload")
}

final class UploadService {
    enum UploadError: LocalizedError {
        case missingVideo

        var errorDescription: String? {
            switch self {
            case .missingVideo:
                return "Recorded video is required before uploading this assessment."
            }
        }
    }

    static let shared = UploadService()

    func useTrialAndUpload(user: User, result: AssessmentResult) async throws {
        let trialBody = ["registration_id": user.registrationID, "assessment_type": result.type.rawValue]
        let _: APIMessageResponse = try await APIClient.shared.request(.useTrial, body: trialBody)
        _ = try await uploadAssessment(user: user, result: result)
    }

    func uploadAssessment(user: User, result: AssessmentResult) async throws -> APIMessageResponse {
        guard let videoURL = result.videoURL else {
            throw UploadError.missingVideo
        }

        var fields: [String: String] = [
            "registration_id": user.registrationID
        ]

        switch result.type {
        case .anxiety:
            fields["gad_score"] = "\(result.score)"
        case .depression:
            fields["phq_score"] = "\(result.score)"
        }

        let files = [
            MultipartFile(fieldName: "video", fileName: videoURL.lastPathComponent, mimeType: videoMimeType(for: videoURL), url: videoURL),
            MultipartFile(fieldName: "au_csv", fileName: result.auCSVURL.lastPathComponent, mimeType: "text/csv", url: result.auCSVURL),
            MultipartFile(fieldName: questionnaireFieldName(for: result.type), fileName: result.questionnaireCSVURL.lastPathComponent, mimeType: "text/csv", url: result.questionnaireCSVURL)
        ]

        return try await APIClient.shared.uploadMultipart(endpoint: .uploadAssessment, fields: fields, files: files)
    }

    func upload(user: User, result: AssessmentResult) async throws -> APIMessageResponse {
        try await uploadAssessment(user: user, result: result)
    }

    private func questionnaireFieldName(for type: AssessmentType) -> String {
        type == .anxiety ? "gad7_csv" : "phq_csv"
    }

    private func videoMimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mov":
            return "video/quicktime"
        case "m4v":
            return "video/x-m4v"
        default:
            return "video/mp4"
        }
    }
}

enum CSVExportService {
    static func writeAUCSV(frames: [AUFrame], prefix: String) throws -> URL {
        let featureCount = AUFrame.featureCount
        let headers = ["timestamp"] + (0..<featureCount).map { index in
            index < AUFeatureSet.canonicalFeatures.count ? AUFeatureSet.canonicalFeatures[index] : "au_\(index + 1)"
        }

        var rows = [headers]
        rows += frames.map { frame in
            var row = [String(frame.timestamp)]
            for index in 0..<featureCount {
                row.append(index < frame.values.count ? String(frame.values[index]) : "0")
            }
            return row
        }

        return try FileManager.default.writeCSV(named: "\(prefix)_\(Int(Date().timeIntervalSince1970)).csv", rows: rows)
    }

    static func writeQuestionnaireCSV(type: AssessmentType, responses: [Int], prefix: String) throws -> URL {
        var rows = [["assessment_type", "question", "score"]]
        rows += responses.enumerated().map { [type.rawValue, String($0.offset + 1), String($0.element)] }
        return try FileManager.default.writeCSV(named: "\(prefix)_\(Int(Date().timeIntervalSince1970)).csv", rows: rows)
    }
}
