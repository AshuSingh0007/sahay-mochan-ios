import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var registrationID = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgot = false
    @State private var showConsent = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SahayMochan")
                            .font(.largeTitle.bold())
                            .foregroundColor(MochanTheme.sageDark)
                        Text("Sahay anxiety care and Mochan depression care in one private workspace.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 36)

                    VStack(spacing: 14) {
                        TextField("Registration ID", text: $registrationID)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task { await auth.login(registrationID: registrationID, password: password) }
                        } label: {
                            if auth.isLoading { ProgressView().tint(.white) } else { Text("Login") }
                        }
                        .mochanButton(disabled: registrationID.isEmpty || password.isEmpty || auth.isLoading)
                        .disabled(registrationID.isEmpty || password.isEmpty || auth.isLoading)
                    }
                    .mochanCard()

                    if let message = auth.errorMessage { Text(message).foregroundColor(MochanTheme.severe) }
                    if let message = auth.infoMessage { Text(message).foregroundColor(MochanTheme.mild) }

                    HStack {
                        Button("Create account") { showConsent = true }
                        Spacer()
                        Button("Forgot password") { showForgot = true }
                    }
                    .foregroundColor(MochanTheme.purple)
                }
                .padding()
            }
            .background(MochanTheme.sageBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showConsent) { ConsentView(onAccept: { showConsent = false; showRegister = true }) }
            .sheet(isPresented: $showRegister) { RegisterView() }
            .sheet(isPresented: $showForgot) { ForgotPasswordView() }
        }
    }
}
