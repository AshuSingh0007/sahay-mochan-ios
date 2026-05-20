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
    let registrationID: String
    let assessmentType: AssessmentType
    let questionnaireScore: Int
    let aiRawScore: Double?
    let severity: Severity
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case registrationID = "registration_id"
        case assessmentType = "assessment_type"
        case questionnaireScore = "questionnaire_score"
        case aiRawScore = "ai_raw_score"
        case severity
        case createdAt = "created_at"
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

struct TrialInfo: Codable, Equatable {
    var registrationID: String? = nil
    var assessmentType: String? = nil
    var remainingTrials: Int? = nil
    var canTake: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case assessmentType = "assessment_type"
        case remainingTrials = "remaining_trials"
        case canTake = "can_take"
    }

    var canTakeAssessment: Bool { canTake ?? false }
}

typealias TrialStatus = TrialInfo
