import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var role: UserRole = .patient
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var pendingRegistrationID: String?

    private let api: APIClient
    private let userStorageKey = "currentUser"
    private let roleStorageKey = "currentUserRole"

    var isAuthenticated: Bool { currentUser != nil }

    init(api: APIClient? = nil) {
        self.api = api ?? APIClient.shared
        loadSession()
    }

    func login(registrationID: String, password: String, role: UserRole) async {
        await run {
            switch role {
            case .patient:
                let response: LoginResponse = try await api.request(.login, body: LoginRequest(registrationID: registrationID, password: password))
                try validateAuthResponse(success: response.success, message: response.message)
                if let token = response.token { KeychainManager.shared.token = token }
                saveAuthenticatedUser(makeUser(from: response, fallbackRegistrationID: registrationID, role: role), role: role)
            case .clinician:
                let response: LoginResponse = try await api.request(.loginClinician(registrationID: registrationID, password: password))
                try validateAuthResponse(success: response.success, message: response.message)
                if let token = response.token { KeychainManager.shared.token = token }
                saveAuthenticatedUser(makeUser(from: response, fallbackRegistrationID: registrationID, role: role), role: role)
            }
        }
    }

    func login(registrationID: String, password: String) async {
        await login(registrationID: registrationID, password: password, role: .patient)
    }

    func register(_ request: RegisterRequest, role: UserRole) async -> String? {
        var generatedID: String?
        await run {
            switch role {
            case .patient:
                let response: RegisterResponse = try await api.request(.register, body: request)
                try validateAuthResponse(success: response.success, message: response.message)
                generatedID = nonEmpty(response.registrationID) ?? response.user?.registrationID
                pendingRegistrationID = generatedID
                sendRegistrationEmail(role: role, name: request.name, email: request.email, identifier: generatedID)
            case .clinician:
                let response: RegisterResponse = try await api.request(.registerClinician, body: request)
                try validateAuthResponse(success: response.success, message: response.message)
                generatedID = nonEmpty(response.clinicianID) ?? nonEmpty(response.registrationID) ?? response.user?.registrationID
                pendingRegistrationID = generatedID
                sendRegistrationEmail(role: role, name: request.name, email: request.email, identifier: generatedID)
            }
        }
        return generatedID
    }

    func register(_ request: RegisterRequest) async {
        _ = await register(request, role: .patient)
    }

    func completeRegistrationLogin(registrationID: String, password: String, role: UserRole) async {
        pendingRegistrationID = nil
        await login(registrationID: registrationID, password: password, role: role)
    }

    func sendOTP(phone: String) async {
        await run(message: "OTP sent") {
            let _: APIMessageResponse = try await api.request(.sendPhoneOTP, body: OTPRequest(phone: phone))
        }
    }

    func verifyOTP(phone: String, otp: String) async {
        await run(message: "Phone verified") {
            let _: APIMessageResponse = try await api.request(.verifyPhoneOTP, body: VerifyOTPRequest(phone: phone, otp: otp))
        }
    }

    func resetPassword(registrationID: String, phone: String, newPassword: String) async {
        await run(message: "Password updated") {
            let _: APIMessageResponse = try await api.request(.verifyPhoneOTP, body: ForgotPasswordRequest(registrationID: registrationID, phone: phone, newPassword: newPassword))
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: userStorageKey)
        UserDefaults.standard.removeObject(forKey: roleStorageKey)
        UserPreferences.shared.clearSession()
        currentUser = nil
        role = .patient
    }

    private func run(message: String? = nil, operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await operation()
            infoMessage = message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func validateAuthResponse(success: Bool?, message: String?) throws {
        if success == false {
            throw APIError.server(status: 200, message: message ?? "Authentication failed.")
        }
    }

    private func saveAuthenticatedUser(_ user: User, role: UserRole) {
        self.currentUser = user
        self.role = role
        UserPreferences.shared.currentUser = user
        saveSession()
    }

    private func saveSession() {
        if let currentUser, let encoded = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(encoded, forKey: userStorageKey)
        }
        UserDefaults.standard.set(role.rawValue, forKey: roleStorageKey)
    }

    private func loadSession() {
        if let rawRole = UserDefaults.standard.string(forKey: roleStorageKey), let storedRole = UserRole(rawValue: rawRole) {
            role = storedRole
        }
        if let data = UserDefaults.standard.data(forKey: userStorageKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        } else {
            currentUser = UserPreferences.shared.currentUser
        }
    }

    private func makeUser(from response: LoginResponse, fallbackRegistrationID: String, role: UserRole) -> User {
        let responseUser = response.user
        let identifier = nonEmpty(responseUser?.registrationID)
            ?? nonEmpty(response.registrationID)
            ?? nonEmpty(response.clinicianID)
            ?? fallbackRegistrationID

        return User(
            userID: nonEmpty(responseUser?.userID) ?? nonEmpty(response.userID),
            registrationID: identifier,
            name: realName(responseUser?.name) ?? realName(response.name) ?? "",
            email: nonEmpty(responseUser?.email) ?? nonEmpty(response.email) ?? "",
            age: validAge(responseUser?.age) ?? validAge(response.age) ?? 0,
            gender: nonEmpty(responseUser?.gender) ?? nonEmpty(response.gender) ?? "",
            phone: nonEmpty(responseUser?.phone) ?? nonEmpty(response.phoneNo) ?? "",
            parentName: nil,
            parentEmail: nil,
            isUnderage: false,
            anonymousID: responseUser?.anonymousID ?? UUID().uuidString
        )
    }

    private func sendRegistrationEmail(role: UserRole, name: String, email: String, identifier: String?) {
        guard let identifier, !email.isEmpty else { return }
        let urlString = role == .patient ? APIConstants.patientEmailScript : APIConstants.clinicianEmailScript
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String]
        if role == .patient {
            payload = ["action": "sendRegistrationId", "name": name, "email": email, "registrationId": identifier]
        } else {
            payload = ["action": "sendClinicianId", "name": name, "email": email, "clinicianId": identifier]
        }
        request.httpBody = try? JSONEncoder().encode(payload)

        Task.detached {
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    private func validAge(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private func realName(_ value: String?) -> String? {
        guard let value = nonEmpty(value) else { return nil }
        let normalized = value.replacingOccurrences(of: " ", with: "").lowercased()
        guard normalized != "sahaymochanuser" else { return nil }
        return value
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
