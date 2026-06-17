import SwiftUI
import UIKit

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthViewModel

    @State private var role: UserRole
    @State private var request = RegisterRequest()
    @State private var confirmPassword = ""
    @State private var generatedID: String?
    @State private var showGeneratedID = false

    init(initialRole: UserRole = .patient) {
        _role = State(initialValue: initialRole)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Account Type") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Profile") {
                    TextField("Name", text: $request.name)
                    TextField("Email", text: $request.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Stepper("Age: \(request.age)", value: $request.age, in: role == .patient ? 18...100 : 0...100)
                    TextField("Gender", text: $request.gender)
                    TextField("Phone", text: $request.phoneNo)
                        .keyboardType(.phonePad)
                    SecureField("Password", text: $request.password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                Section {
                    Button(auth.isLoading ? "Creating..." : "Create Account") {
                        Task { await createAccount() }
                    }
                    .disabled(!canSubmit || auth.isLoading)
                }

                if let message = auth.errorMessage { Text(message).foregroundColor(MochanTheme.severe) }
                if let message = auth.infoMessage { Text(message).foregroundColor(MochanTheme.mild) }
            }
            .navigationTitle("Register")
            .alert("Save Your ID", isPresented: $showGeneratedID) {
                Button("Copy") {
                    UIPasteboard.general.string = generatedID
                }
                Button("Continue") {
                    Task { await continueAfterIDPopup() }
                }
            } message: {
                Text("Your \(role == .patient ? "registration" : "clinician") ID is \(generatedID ?? ""). Copy it before continuing.")
            }
        }
    }

    private var canSubmit: Bool {
        !request.name.isEmpty &&
        !request.email.isEmpty &&
        !request.gender.isEmpty &&
        !request.phoneNo.isEmpty &&
        !request.password.isEmpty &&
        request.password == confirmPassword &&
        (role == .clinician || request.age >= 18)
    }

    private func createAccount() async {
        generatedID = await auth.register(request, role: role)
        showGeneratedID = generatedID != nil
    }

    private func continueAfterIDPopup() async {
        guard let generatedID else { return }
        await auth.completeRegistrationLogin(registrationID: generatedID, password: request.password, role: role)
        if auth.isAuthenticated { dismiss() }
    }
}
