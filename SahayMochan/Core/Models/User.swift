import Foundation

struct User: Codable, Identifiable, Equatable {
    var id: String { registrationID }
    let userID: String?
    let registrationID: String
    var name: String
    var email: String
    var age: Int
    var gender: String
    var phone: String
    var parentName: String?
    var parentEmail: String?
    var isUnderage: Bool
    var anonymousID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case registrationID = "registration_id"
        case name, email, age, gender
        case phone = "phone_no"
        case parentName = "parent_name"
        case parentEmail = "parent_email"
        case isUnderage = "is_underage"
        case anonymousID = "anonymous_id"
    }

    enum LegacyCodingKeys: String, CodingKey {
        case phone
    }

    init(
        userID: String? = nil,
        registrationID: String,
        name: String = "",
        email: String = "",
        age: Int = 0,
        gender: String = "",
        phone: String = "",
        parentName: String? = nil,
        parentEmail: String? = nil,
        isUnderage: Bool = false,
        anonymousID: String = UUID().uuidString
    ) {
        self.userID = userID
        self.registrationID = registrationID
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.phone = phone
        self.parentName = parentName
        self.parentEmail = parentEmail
        self.isUnderage = isUnderage
        self.anonymousID = anonymousID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        registrationID = try container.decodeIfPresent(String.self, forKey: .registrationID) ?? userID ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? legacyContainer?.decodeIfPresent(String.self, forKey: .phone) ?? ""
        parentName = try container.decodeIfPresent(String.self, forKey: .parentName)
        parentEmail = try container.decodeIfPresent(String.self, forKey: .parentEmail)
        isUnderage = try container.decodeIfPresent(Bool.self, forKey: .isUnderage) ?? false
        anonymousID = try container.decodeIfPresent(String.self, forKey: .anonymousID) ?? UUID().uuidString
    }
}
