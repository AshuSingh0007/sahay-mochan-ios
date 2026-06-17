import Combine
import Foundation

@MainActor
final class ClinicianPatientsViewModel: ObservableObject {
    @Published var patients: [ClinicianPatient] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    var filteredPatients: [ClinicianPatient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return patients }
        return patients.filter { patient in
            patient.name.lowercased().contains(query) || patient.registrationID.lowercased().contains(query)
        }
    }

    func load(clinicianID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: ClinicianPatientsResponse = try await APIClient.shared.request(.clinicianPatients(clinicianID: clinicianID))
            patients = response.patients
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
