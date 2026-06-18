import Foundation

// MARK: - Clinical Question
struct ClinicalQuestion: Identifiable, Equatable {
    let id: Int
    let text: String
    let maxScore: Int
}

// MARK: - Patient Model
struct ClinicianPatient: Codable, Identifiable, Equatable {
    var id: String { patientID }   // ✅ Use patientID (UUID) as the unique identifier
    let patientID: String          // ✅ UUID from backend (patient_id)
    let registrationID: String
    let name: String
    let email: String
    let age: Int
    let gender: String

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"      // ✅ Map from backend
        case registrationID = "registration_id"
        case name, email, age, gender
    }

    init(patientID: String, registrationID: String, name: String, email: String, age: Int, gender: String) {
        self.patientID = patientID
        self.registrationID = registrationID
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patientID = try container.decodeIfPresent(String.self, forKey: .patientID) ?? ""
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

// MARK: - Clinical Assessment Request (matches backend)
struct ClinicalAssessmentRequest: Codable {
    let patientID: String
    let clinicianID: String
    let itemScores: [Int]

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case clinicianID = "clinician_id"
        case itemScores = "item_scores"
    }
}

// MARK: - Clinical Assessment Response
struct ClinicalAssessmentResponse: Decodable, Equatable {
    let success: Bool?
    let totalScore: Int
    let severity: String
    let assessmentID: String   // UUID as String

    enum CodingKeys: String, CodingKey {
        case success
        case totalScore = "total_score"
        case severity
        case assessmentID = "assessment_id"
    }
}
