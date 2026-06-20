import Foundation
import SwiftUI

enum AssessmentType: String, Codable, CaseIterable, Identifiable {
    case anxiety
    case depression
    var id: String { rawValue }
    var title: String { self == .anxiety ? "Sahay Anxiety" : "Mochan Depression" }
    var questionnaireName: String { self == .anxiety ? "GAD-7" : "PHQ-9" }
    var maxScore: Int { self == .anxiety ? 21 : 27 }
}

enum Severity: String, Codable, CaseIterable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var color: Color {
        switch self {
        case .mild: return MochanTheme.mild
        case .moderate: return MochanTheme.moderate
        case .severe: return MochanTheme.severe
        }
    }

    static func anxiety(score: Int) -> Severity {
        if score <= 7 { return .mild }
        if score <= 14 { return .moderate }
        return .severe
    }

    static func depression(score: Int) -> Severity {
        if score <= 9 { return .mild }
        if score <= 18 { return .moderate }
        return .severe
    }
}

struct AssessmentRecord: Codable, Identifiable, Equatable {
    let id: Int
    let assessmentScore: Double?
    let gad7Score: Int?
    let phqScore: Int?
    let questionnaireScore: Int
    let createdAt: Date
    let videoCount: Int?
    let assessmentType: AssessmentType

    var aiRawScore: Double? { assessmentScore }
    var severity: Severity {
        assessmentType == .anxiety ? .anxiety(score: questionnaireScore) : .depression(score: questionnaireScore)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assessmentScore = "assessment_score"
        case gad7Score = "gad7_score"
        case gadScore = "gad_score"
        case phqScore = "phq_score"
        case phq9Score = "phq9_score"
        case questionnaireScore = "questionnaire_score"
        case assessmentType = "assessment_type"
        case createdAt = "created_at"
        case videoCount = "video_count"
    }

    init(
        id: Int,
        assessmentScore: Double?,
        gad7Score: Int?,
        phqScore: Int? = nil,
        questionnaireScore: Int,
        createdAt: Date,
        videoCount: Int?,
        assessmentType: AssessmentType = .anxiety
    ) {
        self.id = id
        self.assessmentScore = assessmentScore
        self.gad7Score = gad7Score
        self.phqScore = phqScore
        self.questionnaireScore = questionnaireScore
        self.createdAt = createdAt
        self.videoCount = videoCount
        self.assessmentType = assessmentType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        assessmentScore = try container.decodeIfPresent(Double.self, forKey: .assessmentScore)
        gad7Score = try container.decodeIfPresent(Int.self, forKey: .gad7Score) ?? container.decodeIfPresent(Int.self, forKey: .gadScore)
        phqScore = try container.decodeIfPresent(Int.self, forKey: .phqScore) ?? container.decodeIfPresent(Int.self, forKey: .phq9Score)
        videoCount = try container.decodeIfPresent(Int.self, forKey: .videoCount)

        let typeValue = try container.decodeIfPresent(String.self, forKey: .assessmentType)?.lowercased()
        assessmentType = AssessmentType(rawValue: typeValue ?? "") ?? (phqScore != nil ? .depression : .anxiety)
        questionnaireScore = try container.decodeIfPresent(Int.self, forKey: .questionnaireScore) ?? gad7Score ?? phqScore ?? 0

        let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        createdAt = Self.parseDate(dateString) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(assessmentScore, forKey: .assessmentScore)
        try container.encodeIfPresent(gad7Score, forKey: .gad7Score)
        try container.encodeIfPresent(phqScore, forKey: .phqScore)
        try container.encode(questionnaireScore, forKey: .questionnaireScore)
        try container.encode(assessmentType.rawValue, forKey: .assessmentType)
        try container.encode(Self.apiDateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encodeIfPresent(videoCount, forKey: .videoCount)
    }

    private static func parseDate(_ value: String) -> Date? {
        apiDateFormatter.date(from: value) ?? isoDateFormatter.date(from: value)
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static let isoDateFormatter = ISO8601DateFormatter()
}

struct AssessmentHistoryResponse: Codable {
    var success: Bool = false
    var studentID: String = ""
    var totalAssessments: Int = 0
    var assessments: [AssessmentRecord] = []

    enum CodingKeys: String, CodingKey {
        case success
        case studentID = "student_id"
        case totalAssessments = "total_assessments"
        case assessments
    }
}

struct AssessmentResult: Equatable {
    let type: AssessmentType
    let score: Int
    let severity: Severity
    let aiScore: Double?
    let videoURL: URL?
    let auCSVURL: URL
    let questionnaireCSVURL: URL
}

// MARK: - Corrected Trial Check Response (matches actual backend)
struct TrialCheckResponse: Codable, Equatable {
    let success: Bool
    let canProceed: Bool
    let assessmentType: String
    let trialsRemaining: Int
    let totalTrials: Int
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case canProceed = "can_proceed"
        case assessmentType = "assessment_type"
        case trialsRemaining = "trials_remaining"
        case totalTrials = "total_trials"
        case message
    }

    func remainingTrials(for type: AssessmentType) -> Int {
        return trialsRemaining
    }

    func canTake(for type: AssessmentType) -> Bool {
        return canProceed
    }
}

// Keep the typealias for backward compatibility
typealias TrialStatus = TrialCheckResponse
