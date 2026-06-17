import Foundation

struct APIMessageResponse: Codable {
    var success: Bool? = nil
    var message: String? = nil
    var assessmentID: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case assessmentID = "assessment_id"
    }
}

struct ErrorResponse: Codable {
    var success: Bool? = nil
    var message: String? = nil
    var error: String? = nil
    var detail: String? = nil
    var registrationID: String? = nil
    var userID: String? = nil

    enum CodingKeys: String, CodingKey {
        case success, message, error, detail
        case registrationID = "registration_id"
        case userID = "user_id"
    }

    var displayMessage: String {
        message ?? error ?? detail ?? "Request failed."
    }
}

struct EmptyResponse: Codable {}

enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid response."
        case .server(_, let message): return message
        case .decoding(let error): return "Unable to read server response: \(error.localizedDescription)"
        case .transport(let error): return error.localizedDescription
        }
    }
}
