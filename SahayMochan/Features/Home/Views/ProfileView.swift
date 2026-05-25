import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showDelete = false
    @State private var deleteText = ""

    var body: some View {
        NavigationView {
            List {
                if let user = auth.currentUser {
                    Section("Profile") {
                        row("Name", display(user.name, fallback: user.registrationID))
                        row("Email", display(user.email))
                        row("Registration ID", display(user.registrationID))
                        row("Age", user.age > 0 ? "\(user.age)" : "--")
                        row("Gender", display(user.gender))
                        row("Phone", display(user.phone))
                        row("Anonymous ID", display(user.anonymousID))
                    }

                    if user.isUnderage || user.parentName != nil || user.parentEmail != nil {
                        Section("Parent or Guardian") {
                            row("Name", display(user.parentName))
                            row("Email", display(user.parentEmail))
                        }
                    }
                } else {
                    Section("Profile") {
                        Text("No signed-in user.")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Logout", role: .destructive) { auth.logout() }
                    Button("Delete Account", role: .destructive) { showDelete = true }
                }
            }
            .navigationTitle("Profile")
            .alert("Delete Account", isPresented: $showDelete) {
                TextField("Type DELETE", text: $deleteText)
                Button("Cancel", role: .cancel) { deleteText = "" }
                Button("Delete", role: .destructive) { auth.logout() }
                    .disabled(deleteText != "DELETE")
            } message: {
                Text("This removes the local session. Server-side deletion should be handled by the account API when available.")
            }
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
