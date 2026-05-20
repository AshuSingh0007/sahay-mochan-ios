import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthViewModel
    @State private var registrationID = ""
    @State private var phone = ""
    @State private var otp = ""
    @State private var newPassword = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Verify Account") {
                    TextField("Registration ID", text: $registrationID).autocapitalization(.none)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    Button("Send OTP") { Task { await auth.sendOTP(phone: phone) } }.disabled(phone.isEmpty)
                    TextField("OTP", text: $otp).keyboardType(.numberPad)
                    Button("Verify OTP") { Task { await auth.verifyOTP(phone: phone, otp: otp) } }.disabled(otp.isEmpty)
                }
                Section("New Password") {
                    SecureField("New password", text: $newPassword)
                    Button("Update Password") {
                        Task { await auth.resetPassword(registrationID: registrationID, phone: phone, newPassword: newPassword); if auth.errorMessage == nil { dismiss() } }
                    }
                    .disabled(registrationID.isEmpty || phone.isEmpty || newPassword.isEmpty || auth.isLoading)
                }
                if let message = auth.errorMessage { Text(message).foregroundColor(MochanTheme.severe) }
                if let message = auth.infoMessage { Text(message).foregroundColor(MochanTheme.mild) }
            }
            .navigationTitle("Forgot Password")
        }
    }
}
