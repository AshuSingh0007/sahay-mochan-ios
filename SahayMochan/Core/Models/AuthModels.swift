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

struct LoginResponse: Decodable {
    var success: Bool? = nil
    var message: String? = nil
    var user: User? = nil
    var registrationID: String? = nil
    var userID: String? = nil
    var token: String? = nil
    var name: String? = nil
    var email: String? = nil
    var age: Int? = nil
    var gender: String? = nil
    var phoneNo: String? = nil

    enum CodingKeys: String, CodingKey {
        case success, message, user, token, name, email, age, gender, data, student, profile
        case registrationID = "registration_id"
        case userID = "user_id"
        case phoneNo = "phone_no"
        case phone
        case phoneNumber = "phone_number"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        user = try container.decodeIfPresent(User.self, forKey: .user)
            ?? container.decodeIfPresent(User.self, forKey: .data)
            ?? container.decodeIfPresent(User.self, forKey: .student)
            ?? container.decodeIfPresent(User.self, forKey: .profile)
        registrationID = try container.decodeIfPresent(String.self, forKey: .registrationID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        phoneNo = try container.decodeIfPresent(String.self, forKey: .phoneNo)
            ?? container.decodeIfPresent(String.self, forKey: .phone)
            ?? container.decodeIfPresent(String.self, forKey: .phoneNumber)
    }
}

struct RegisterResponse: Decodable {
    var success: Bool? = nil
    var message: String? = nil
    var user: User? = nil
    var registrationID: String? = nil
    var userID: String? = nil
    var token: String? = nil
    var name: String? = nil
    var email: String? = nil
    var age: Int? = nil
    var gender: String? = nil
    var phoneNo: String? = nil

    enum CodingKeys: String, CodingKey {
        case success, message, user, token, name, email, age, gender, data, student, profile
        case registrationID = "registration_id"
        case userID = "user_id"
        case phoneNo = "phone_no"
        case phone
        case phoneNumber = "phone_number"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        user = try container.decodeIfPresent(User.self, forKey: .user)
            ?? container.decodeIfPresent(User.self, forKey: .data)
            ?? container.decodeIfPresent(User.self, forKey: .student)
            ?? container.decodeIfPresent(User.self, forKey: .profile)
        registrationID = try container.decodeIfPresent(String.self, forKey: .registrationID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        phoneNo = try container.decodeIfPresent(String.self, forKey: .phoneNo)
            ?? container.decodeIfPresent(String.self, forKey: .phone)
            ?? container.decodeIfPresent(String.self, forKey: .phoneNumber)
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
