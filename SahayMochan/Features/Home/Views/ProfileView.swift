import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showDelete = false
    @State private var deleteText = ""

    var body: some View {
        NavigationView {
            List {
                if let user = auth.currentUser {
                    Section("Profile") {
                        row("Name", user.name)
                        row("Email", user.email)
                        row("Age", "\(user.age)")
                        row("Gender", user.gender)
                        row("Phone", user.phone)
                        row("Registration ID", user.registrationID)
                    }
                    if user.isUnderage {
                        Section("Parent or Guardian") {
                            row("Name", user.parentName ?? "")
                            row("Email", user.parentEmail ?? "")
                        }
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
                Button("Delete", role: .destructive) { auth.logout() }.disabled(deleteText != "DELETE")
            } message: { Text("This removes the local session. Server-side deletion should be handled by the account API when available.") }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundColor(.secondary) }
    }
}
