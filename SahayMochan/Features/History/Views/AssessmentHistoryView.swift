import SwiftUI

struct AssessmentHistoryView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HistoryViewModel()
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if viewModel.records.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No assessments uploaded yet")
                                .font(.headline)
                                .foregroundColor(MochanTheme.sageDark)
                            Text("Completed uploads will appear here after the history API returns them.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                if !viewModel.records.isEmpty {
                    Section("Assessments") {
                        ForEach(viewModel.records) { record in
                            recordRow(record)
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        if let id = auth.currentUser?.registrationID {
                                            Task { await viewModel.delete(record, registrationID: id) }
                                        }
                                    }
                                }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(MochanTheme.severe)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                Button("Delete All") { confirmDeleteAll = true }
                    .disabled(viewModel.records.isEmpty || viewModel.isLoading)
            }
            .alert("Delete all assessments?", isPresented: $confirmDeleteAll) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    if let id = auth.currentUser?.registrationID {
                        Task { await viewModel.deleteAll(registrationID: id) }
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .onReceive(NotificationCenter.default.publisher(for: .assessmentDidUpload)) { _ in
                Task { await load() }
            }
        }
    }

    private func load() async {
        if let id = auth.currentUser?.registrationID {
            await viewModel.load(registrationID: id)
        }
    }

    private func recordRow(_ record: AssessmentRecord) -> some View {
        let questionnaireLevel = viewModel.questionnaireLevel(for: record)
        let aiLevel = viewModel.aiLevel(for: record)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.assessmentType.title)
                    .font(.headline)
                    .foregroundColor(MochanTheme.sageDark)
                Spacer()
                Text(DateFormatter.shortDateTime.string(from: record.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            levelRow(title: "Questionnaire Level", severity: questionnaireLevel)
            levelRow(title: "AI Analysis Level", severity: aiLevel)
        }
        .padding(.vertical, 6)
    }

    private func levelRow(title: String, severity: Severity) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(severity.rawValue)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severity.color.opacity(0.16))
                .foregroundColor(severity.color)
                .cornerRadius(8)
        }
        .font(.subheadline)
    }
}
