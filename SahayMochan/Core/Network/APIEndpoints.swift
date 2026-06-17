import Foundation

enum APIEndpoint {
    static let baseURL = URL(string: APIConstants.baseURL)!

    case login
    case loginClinician(registrationID: String, password: String)
    case register
    case registerClinician
    case sendPhoneOTP
    case verifyPhoneOTP
    case checkTrials(registrationID: String, type: AssessmentType)
    case useTrial
    case useTrialAfterUpload(assessmentID: String)      // ✅ Changed to String
    case assessments(registrationID: String)
    case deleteAssessment(id: Int)
    case deleteAll(registrationID: String)
    case uploadAssessment
    case clinicianPatients(clinicianID: String)
    case hamaAssessment
    case hdrsAssessment
    case severityDirect(assessmentType: String, assessmentID: String, severity: String)   // ✅ Changed to String

    var method: String {
        switch self {
        case .checkTrials, .assessments, .clinicianPatients:
            return "GET"
        case .deleteAssessment, .deleteAll:
            return "DELETE"
        default:
            return "POST"
        }
    }

    var url: URL {
        switch self {
        case .login:
            return Self.baseURL.appendingPathComponent("login-user")
        case .loginClinician(let registrationID, let password):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("login-clinician"), resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "registration_id", value: registrationID),
                URLQueryItem(name: "password", value: password)
            ]
            return components.url!
        case .register:
            return Self.baseURL.appendingPathComponent("register-patient")
        case .registerClinician:
            return Self.baseURL.appendingPathComponent("register-clinician")
        case .sendPhoneOTP:
            return Self.baseURL.appendingPathComponent("send-phone-otp")
        case .verifyPhoneOTP:
            return Self.baseURL.appendingPathComponent("verify-phone-otp")
        case .checkTrials(let registrationID, let type):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/trials/check/\(registrationID)"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "assessment_type", value: type.rawValue)]
            return components.url!
        case .useTrial:
            return Self.baseURL.appendingPathComponent("api/trials/use-trial")
        case .useTrialAfterUpload(let assessmentID):
            return Self.baseURL.appendingPathComponent("api/trials/use/\(assessmentID)")  // ✅ uses String
        case .assessments(let registrationID):
            return Self.baseURL.appendingPathComponent("api/student/\(registrationID)/assessments")
        case .deleteAssessment(let id):
            return Self.baseURL.appendingPathComponent("api/assessment/\(id)")
        case .deleteAll(let registrationID):
            return Self.baseURL.appendingPathComponent("api/student/delete-all/\(registrationID)")
        case .uploadAssessment:
            return Self.baseURL.appendingPathComponent("api/student/assessment")
        case .clinicianPatients(let clinicianID):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/clinician/patients"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "clinician_id", value: clinicianID)]
            return components.url!
        case .hamaAssessment:
            return Self.baseURL.appendingPathComponent("api/assessments/ham-a")
        case .hdrsAssessment:
            return Self.baseURL.appendingPathComponent("api/assessments/hdrs")
        case .severityDirect(let assessmentType, let assessmentID, let severity):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("api/severity/direct"), resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "assessment_type", value: assessmentType),
                URLQueryItem(name: "assessment_id", value: assessmentID),   // ✅ uses String directly
                URLQueryItem(name: "severity", value: severity)
            ]
            return components.url!
        }
    }
}
