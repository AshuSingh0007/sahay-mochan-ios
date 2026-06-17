import Foundation

struct ClinicianPatient: Codable, Identifiable, Equatable {
    var id: String { registrationID }
    let registrationID: String
    let name: String
    let email: String
    let age: Int
    let gender: String

    enum CodingKeys: String, CodingKey {
        case registrationID = "registration_id"
        case name, email, age, gender
    }

    init(registrationID: String, name: String, email: String, age: Int, gender: String) {
        self.registrationID = registrationID
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        registrationID = try container.decodeIfPresent(String.self, forKey: .registrationID) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""
    }
}

struct ClinicianPatientsResponse: Decodable {
    let patients: [ClinicianPatient]

    enum CodingKeys: String, CodingKey { case patients, data }

    init(from decoder: Decoder) throws {
        if let array = try? [ClinicianPatient](from: decoder) {
            patients = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patients = try container.decodeIfPresent([ClinicianPatient].self, forKey: .patients)
            ?? container.decodeIfPresent([ClinicianPatient].self, forKey: .data)
            ?? []
    }
}

struct ClinicalAssessmentResponse: Decodable, Equatable {
    let totalScore: Int
    let severity: String
    let assessmentID: Int

    enum CodingKeys: String, CodingKey {
        case totalScore = "total_score"
        case severity
        case assessmentID = "assessment_id"
    }
}
