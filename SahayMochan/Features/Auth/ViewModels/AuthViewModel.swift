import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let api: APIClient

    var isAuthenticated: Bool { currentUser != nil }

    init(api: APIClient? = nil) {
        self.api = api ?? APIClient.shared
        currentUser = UserPreferences.shared.currentUser
    }

    func login(registrationID: String, password: String) async {
        await run {
            let response: LoginResponse = try await api.request(.login, body: LoginRequest(registrationID: registrationID, password: password))
            try validateAuthResponse(success: response.success, message: response.message)
            if let token = response.token { KeychainManager.shared.token = token }
            saveAuthenticatedUser(makeUser(from: response, fallbackRegistrationID: registrationID))
        }
    }

    func register(_ request: RegisterRequest) async {
        await run {
            let response = try await api.register(request)
            try validateAuthResponse(success: response.success, message: response.message)
            if let token = response.token { KeychainManager.shared.token = token }
            saveAuthenticatedUser(makeUser(from: response, request: request))
        }
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
        UserPreferences.shared.clearSession()
        currentUser = nil
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

    private func saveAuthenticatedUser(_ user: User) {
        UserPreferences.shared.currentUser = user
        currentUser = user
    }

    private func makeUser(from response: LoginResponse, fallbackRegistrationID: String) -> User {
        let responseUser = response.user
        let cachedUser = cachedUser(matching: fallbackRegistrationID, responseRegistrationID: responseUser?.registrationID ?? response.registrationID)
        let registrationID = nonEmpty(responseUser?.registrationID) ?? nonEmpty(response.registrationID) ?? cachedUser?.registrationID ?? fallbackRegistrationID

        return User(
            userID: nonEmpty(responseUser?.userID) ?? nonEmpty(response.userID) ?? cachedUser?.userID,
            registrationID: registrationID,
            name: nonEmpty(responseUser?.name) ?? nonEmpty(response.name) ?? cachedUser?.name ?? "",
            email: nonEmpty(responseUser?.email) ?? nonEmpty(response.email) ?? cachedUser?.email ?? "",
            age: validAge(responseUser?.age) ?? validAge(response.age) ?? validAge(cachedUser?.age) ?? 0,
            gender: nonEmpty(responseUser?.gender) ?? nonEmpty(response.gender) ?? cachedUser?.gender ?? "",
            phone: nonEmpty(responseUser?.phone) ?? nonEmpty(response.phoneNo) ?? cachedUser?.phone ?? "",
            parentName: nonEmpty(responseUser?.parentName) ?? cachedUser?.parentName,
            parentEmail: nonEmpty(responseUser?.parentEmail) ?? cachedUser?.parentEmail,
            isUnderage: responseUser?.isUnderage ?? cachedUser?.isUnderage ?? false,
            anonymousID: nonEmpty(responseUser?.anonymousID) ?? cachedUser?.anonymousID ?? UUID().uuidString
        )
    }

    private func makeUser(from response: RegisterResponse, request: RegisterRequest) -> User {
        let responseUser = response.user
        let registrationID = nonEmpty(responseUser?.registrationID) ?? nonEmpty(response.registrationID) ?? request.registrationID

        return User(
            userID: nonEmpty(responseUser?.userID) ?? nonEmpty(response.userID),
            registrationID: registrationID,
            name: nonEmpty(responseUser?.name) ?? nonEmpty(response.name) ?? request.name,
            email: nonEmpty(responseUser?.email) ?? nonEmpty(response.email) ?? request.email,
            age: validAge(responseUser?.age) ?? validAge(response.age) ?? request.age,
            gender: nonEmpty(responseUser?.gender) ?? nonEmpty(response.gender) ?? request.gender,
            phone: nonEmpty(responseUser?.phone) ?? nonEmpty(response.phoneNo) ?? request.phoneNo,
            parentName: nonEmpty(responseUser?.parentName) ?? nonEmpty(request.parentName),
            parentEmail: nonEmpty(responseUser?.parentEmail) ?? nonEmpty(request.parentEmail),
            isUnderage: responseUser?.isUnderage ?? request.isUnderage,
            anonymousID: nonEmpty(responseUser?.anonymousID) ?? UUID().uuidString
        )
    }

    private func cachedUser(matching loginRegistrationID: String, responseRegistrationID: String?) -> User? {
        guard let cached = UserPreferences.shared.currentUser else { return nil }
        let candidates = [loginRegistrationID, responseRegistrationID].compactMap(nonEmpty)
        guard candidates.contains(cached.registrationID) else { return nil }
        return cached
    }

    private func validAge(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
