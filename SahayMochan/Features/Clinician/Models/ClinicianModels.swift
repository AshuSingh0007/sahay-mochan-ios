import Foundation

// MARK: - Clinical Question
struct ClinicalQuestion: Identifiable, Equatable {
    let id: Int
    let text: String
    let maxScore: Int
}

// MARK: - Patient Model
struct ClinicianPatient: Codable, Identifiable, Equatable {
    var id: String { patientID }
    let patientID: String          // UUID from backend (patient_id)
    let registrationID: String
    let name: String
    let email: String
    let age: Int
    let gender: String

    // ✅ Latest clinical scores and dates (from backend)
    let latestHamAScore: Int?
    let latestHDRSScore: Int?
    let lastHamADate: Date?
    let lastHDRSDate: Date?
    let lastSelfAssessmentDate: Date?

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case registrationID = "registration_id"
        case name, email, age, gender
        case latestHamAScore = "latest_ham_a_score"
        case latestHDRSScore = "latest_hdrs_score"
        case lastHamADate = "last_ham_a"
        case lastHDRSDate = "last_hdrs"
        case lastSelfAssessmentDate = "last_self_assessment"
    }

    init(patientID: String, registrationID: String, name: String, email: String, age: Int, gender: String,
         latestHamAScore: Int? = nil, latestHDRSScore: Int? = nil,
         lastHamADate: Date? = nil, lastHDRSDate: Date? = nil,
         lastSelfAssessmentDate: Date? = nil) {
        self.patientID = patientID
        self.registrationID = registrationID
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.latestHamAScore = latestHamAScore
        self.latestHDRSScore = latestHDRSScore
        self.lastHamADate = lastHamADate
        self.lastHDRSDate = lastHDRSDate
        self.lastSelfAssessmentDate = lastSelfAssessmentDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patientID = try container.decodeIfPresent(String.self, forKey: .patientID) ?? ""
        registrationID = try container.decodeIfPresent(String.self, forKey: .registrationID) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""

        latestHamAScore = try container.decodeIfPresent(Int.self, forKey: .latestHamAScore)
        latestHDRSScore = try container.decodeIfPresent(Int.self, forKey: .latestHDRSScore)

        // Decode dates using ISO8601DateFormatter (backend returns strings like "2026-06-05T15:39:36.228975")
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastHamADate) {
            lastHamADate = dateFormatter.date(from: dateString)
        } else {
            lastHamADate = nil
        }
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastHDRSDate) {
            lastHDRSDate = dateFormatter.date(from: dateString)
        } else {
            lastHDRSDate = nil
        }
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastSelfAssessmentDate) {
            lastSelfAssessmentDate = dateFormatter.date(from: dateString)
        } else {
            lastSelfAssessmentDate = nil
        }
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
