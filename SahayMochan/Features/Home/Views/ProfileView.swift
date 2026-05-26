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
                        // ✅ Show real name – no fallback to registration ID
                        row("Name", user.name.isEmpty ? "Not set" : user.name)
                        row("Email", user.email.isEmpty ? "Not set" : user.email)
                        row("Registration ID", user.registrationID)
                        row("Age", user.age > 0 ? "\(user.age)" : "--")
                        row("Gender", user.gender.isEmpty ? "Not set" : user.gender)
                        row("Phone", user.phone.isEmpty ? "Not set" : user.phone)
                        row("Anonymous ID", user.anonymousID)
                    }

                    if user.isUnderage || user.parentName != nil || user.parentEmail != nil {
                        Section("Parent or Guardian") {
                            row("Name", user.parentName ?? "Not set")
                            row("Email", user.parentEmail ?? "Not set")
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
}
