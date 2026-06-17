import SwiftUI

struct ClinicianDashboardView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = ClinicianPatientsViewModel()

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search patients", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if viewModel.isLoading {
                    ProgressView()
                }

                Section("Patients") {
                    ForEach(viewModel.filteredPatients) { patient in
                        NavigationLink {
                            PatientDetailView(patient: patient)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patient.name.isEmpty ? patient.registrationID : patient.name)
                                    .font(.headline)
                                Text(patient.registrationID)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(MochanTheme.severe)
                }
            }
            .navigationTitle("Clinician")
            .toolbar { Button("Logout") { auth.logout() } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // ✅ FIX: Use the clinician's UUID (userID) instead of registration_id
    private func load() async {
        if let id = auth.currentUser?.userID {
            await viewModel.load(clinicianID: id)
        }
    }
}
