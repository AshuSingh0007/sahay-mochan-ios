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
            let user = makeUser(from: response, fallbackRegistrationID: registrationID)
            UserPreferences.shared.currentUser = user
            currentUser = user
        }
    }

    func register(_ request: RegisterRequest) async {
        await run {
            let response = try await api.register(request)
            try validateAuthResponse(success: response.success, message: response.message)
            if let token = response.token { KeychainManager.shared.token = token }
            let user = makeUser(from: response, request: request)
            UserPreferences.shared.currentUser = user
            currentUser = user
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

    private func makeUser(from response: LoginResponse, fallbackRegistrationID: String) -> User {
        let responseUser = response.user
        let registrationID = nonEmpty(responseUser?.registrationID) ?? nonEmpty(response.registrationID) ?? fallbackRegistrationID

        return User(
            userID: responseUser?.userID ?? response.userID,
            registrationID: registrationID,
            name: responseUser?.name.isEmpty == false ? responseUser?.name ?? "" : "SahayMochan User",
            email: responseUser?.email ?? "",
            age: responseUser?.age ?? 18,
            gender: responseUser?.gender ?? "",
            phone: responseUser?.phone ?? "",
            parentName: responseUser?.parentName,
            parentEmail: responseUser?.parentEmail,
            isUnderage: responseUser?.isUnderage ?? false,
            anonymousID: responseUser?.anonymousID ?? UUID().uuidString
        )
    }

    private func makeUser(from response: RegisterResponse, request: RegisterRequest) -> User {
        let responseUser = response.user
        let registrationID = nonEmpty(responseUser?.registrationID) ?? nonEmpty(response.registrationID) ?? request.registrationID

        return User(
            userID: responseUser?.userID ?? response.userID,
            registrationID: registrationID,
            name: responseUser?.name.isEmpty == false ? responseUser?.name ?? "" : request.name,
            email: responseUser?.email.isEmpty == false ? responseUser?.email ?? "" : request.email,
            age: responseUser?.age == 0 ? request.age : responseUser?.age ?? request.age,
            gender: responseUser?.gender.isEmpty == false ? responseUser?.gender ?? "" : request.gender,
            phone: responseUser?.phone.isEmpty == false ? responseUser?.phone ?? "" : request.phoneNo,
            parentName: responseUser?.parentName ?? (request.parentName.isEmpty ? nil : request.parentName),
            parentEmail: responseUser?.parentEmail ?? (request.parentEmail.isEmpty ? nil : request.parentEmail),
            isUnderage: responseUser?.isUnderage ?? request.isUnderage,
            anonymousID: responseUser?.anonymousID ?? UUID().uuidString
        )
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
