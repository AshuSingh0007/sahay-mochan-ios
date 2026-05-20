import Foundation

struct LoginRequest: Codable {
    let registrationID: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case password
    }
}

struct RegisterRequest: Codable {
    var registrationID: String = ""
    var name: String = ""
    var email: String = ""
    var age: Int = 18 { didSet { isUnderage = age < 18 } }
    var gender: String = ""
    var phoneNo: String = ""
    var password: String = ""
    var parentName: String = ""
    var parentEmail: String = ""
    var isUnderage: Bool = false

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case phoneNo = "phone_no"
        case name, email, age, gender, password
        case parentName = "parent_name"
        case parentEmail = "parent_email"
        case isUnderage = "is_underage"
    }
}

struct LoginResponse: Codable {
    var success: Bool? = nil
    var message: String? = nil
    var user: User? = nil
    var registrationID: String? = nil
    var userID: String? = nil
    var token: String? = nil

    enum CodingKeys: String, CodingKey {
        case success, message, user, token
        case registrationID = "registration_id"
        case userID = "user_id"
    }
}

struct RegisterResponse: Codable {
    var success: Bool? = nil
    var message: String? = nil
    var user: User? = nil
    var registrationID: String? = nil
    var userID: String? = nil
    var token: String? = nil

    enum CodingKeys: String, CodingKey {
        case success, message, user, token
        case registrationID = "registration_id"
        case userID = "user_id"
    }
}

typealias AuthResponse = LoginResponse

struct OTPRequest: Codable {
    let phone: String
}

struct VerifyOTPRequest: Codable {
    let phone: String
    let otp: String
}

struct ForgotPasswordRequest: Codable {
    let registrationID: String
    let phone: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case phone
        case newPassword = "new_password"
    }
}
