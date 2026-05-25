import Foundation

enum APIEndpoint {
    static let baseURL = URL(string: "http://203.110.243.202:8000")!

    case login
    case register
    case sendPhoneOTP
    case verifyPhoneOTP
    case checkTrials(registrationID: String, type: AssessmentType)
    case useTrial
    case assessments(registrationID: String)
    case deleteAssessment(id: Int)
    case deleteAll(registrationID: String)
    case uploadAssessment

    var method: String {
        switch self {
        case .checkTrials, .assessments: return "GET"
        case .deleteAssessment, .deleteAll: return "DELETE"
        default: return "POST"
        }
    }

    var url: URL {
        switch self {
        case .login: return Self.baseURL.appendingPathComponent("login-user")
        case .register: return Self.baseURL.appendingPathComponent("register-user")
        case .sendPhoneOTP: return Self.baseURL.appendingPathComponent("send-phone-otp")
        case .verifyPhoneOTP: return Self.baseURL.appendingPathComponent("verify-phone-otp")
        case .checkTrials(let registrationID, let type):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/trials/check/\(registrationID)"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "assessment_type", value: type.rawValue)]
            return components.url!
        case .useTrial: return Self.baseURL.appendingPathComponent("api/trials/use-trial")
        case .assessments(let registrationID): return Self.baseURL.appendingPathComponent("api/student/\(registrationID)/assessments")
        case .deleteAssessment(let id): return Self.baseURL.appendingPathComponent("api/assessment/\(id)")
        case .deleteAll(let registrationID): return Self.baseURL.appendingPathComponent("api/student/delete-all/\(registrationID)")
        case .uploadAssessment: return Self.baseURL.appendingPathComponent("api/student/assessment")
        }
    }
}
