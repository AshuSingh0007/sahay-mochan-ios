import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        NavigationView {
            List {
                if let user = auth.currentUser {
                    Section("Profile") {
                        row("Name", display(user.name, fallback: "Loading..."))
                        row("Email", display(user.email))
                        row(auth.role == .clinician ? "Clinician ID" : "Registration ID", display(user.registrationID))
                        row("Age", user.age > 0 ? "\(user.age)" : "--")
                        row("Gender", display(user.gender))
                    }
                } else {
                    Section("Profile") {
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Logout", role: .destructive) { auth.logout() }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private func display(_ value: String?, fallback: String = "--") -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return fallback }
        let normalized = value.replacingOccurrences(of: " ", with: "").lowercased()
        guard normalized != "sahaymochanuser" else { return fallback }
        return value
    }
}
