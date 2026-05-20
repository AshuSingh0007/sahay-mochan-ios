import SwiftUI
import Combine

struct AssessmentHistoryView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HistoryViewModel()
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading { ProgressView() }
                ForEach(viewModel.records) { record in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(record.assessmentType.title).font(.headline)
                            Spacer()
                            Text(record.severity.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(record.severity.color.opacity(0.16))
                                .foregroundColor(record.severity.color)
                                .cornerRadius(8)
                        }
                        Text("Score: \(record.questionnaireScore)")
                        Text(DateFormatter.shortDateTime.string(from: record.createdAt)).font(.caption).foregroundColor(.secondary)
                    }
                    .swipeActions { Button("Delete", role: .destructive) { if let id = auth.currentUser?.registrationID { Task { await viewModel.delete(record, registrationID: id) } } } }
                }
                if let error = viewModel.errorMessage { Text(error).foregroundColor(MochanTheme.severe) }
            }
            .navigationTitle("History")
            .toolbar { Button("Delete All") { confirmDeleteAll = true }.disabled(viewModel.records.isEmpty) }
            .alert("Delete all assessments?", isPresented: $confirmDeleteAll) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) { if let id = auth.currentUser?.registrationID { Task { await viewModel.deleteAll(registrationID: id) } } }
            }
            .task { if let id = auth.currentUser?.registrationID { await viewModel.load(registrationID: id) } }
        }
    }
}
