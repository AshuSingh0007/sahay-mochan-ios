import SwiftUI
import Combine

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthViewModel
    @State private var request = RegisterRequest()

    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    TextField("Registration ID", text: $request.registrationID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Name", text: $request.name)
                    TextField("Email", text: $request.email).keyboardType(.emailAddress).autocapitalization(.none)
                    Stepper("Age: \(request.age)", value: $request.age, in: 8...100)
                    TextField("Gender", text: $request.gender)
                    TextField("Phone", text: $request.phoneNo).keyboardType(.phonePad)
                    SecureField("Password", text: $request.password)
                }
                if request.isUnderage {
                    Section("Parent or Guardian") {
                        TextField("Parent name", text: $request.parentName)
                        TextField("Parent email", text: $request.parentEmail).keyboardType(.emailAddress).autocapitalization(.none)
                    }
                }
                Section {
                    Button { Task { await auth.register(request); if auth.isAuthenticated { dismiss() } } } label: { Text(auth.isLoading ? "Creating..." : "Create Account") }
                        .disabled(!canSubmit || auth.isLoading)
                }
                if let message = auth.errorMessage { Text(message).foregroundColor(MochanTheme.severe) }
                if let message = auth.infoMessage { Text(message).foregroundColor(MochanTheme.mild) }
            }
            .navigationTitle("Register")
        }
    }

    private var canSubmit: Bool {
        !request.registrationID.isEmpty && !request.name.isEmpty && !request.email.isEmpty && !request.phoneNo.isEmpty && !request.password.isEmpty && (!request.isUnderage || (!request.parentName.isEmpty && !request.parentEmail.isEmpty))
    }
}
