import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSahay = false
    @State private var showMochan = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome, \(displayName)")
                        .font(.title2.bold())
                        .foregroundColor(MochanTheme.sageDark)

                    HStack(spacing: 12) {
                        Button {
                            Task { await openAssessment(.anxiety) }
                        } label: {
                            assessmentCard(title: "Sahay", subtitle: "GAD-7 anxiety", systemImage: "waveform.path.ecg", type: .anxiety)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await openAssessment(.depression) }
                        } label: {
                            assessmentCard(title: "Mochan", subtitle: "PHQ-9 depression", systemImage: "heart.text.square", type: .depression)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Wellness Tools")
                        .font(.headline)
                        .foregroundColor(MochanTheme.sageDark)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        tool("Breathing", "lungs", BreathingView())
                        tool("Grounding", "hand.raised", GroundingView())
                        tool("Journal", "book", JournalView())
                        tool("Mood", "face.smiling", MoodTrackerView())
                        tool("Sleep", "moon.zzz", SleepTrackerView())
                        tool("Water", "drop", WaterTrackerView())
                    }

                    if let error = viewModel.errorMessage { Text(error).foregroundColor(MochanTheme.severe) }
                }
                .padding()
            }
            .background(MochanTheme.sageBackground.ignoresSafeArea())
            .navigationTitle("SahayMochan")
            .background(
                NavigationLink("", isActive: $showSahay) { SahayAssessmentView() }.hidden()
            )
            .background(
                NavigationLink("", isActive: $showMochan) { MochanAssessmentView() }.hidden()
            )
            .alert("Assessment unavailable", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
        .task {
            if let user = auth.currentUser {
                await viewModel.refreshTrials(for: user)
            }
        }
        // ✅ Listen for refresh notification to update trials immediately
        .onReceive(NotificationCenter.default.publisher(for: .refreshTrials)) { _ in
            if let user = auth.currentUser {
                Task { await viewModel.refreshTrials(for: user) }
            }
        }
    }

    private func openAssessment(_ type: AssessmentType) async {
        guard let user = auth.currentUser else { return }
        let canProceed = await viewModel.canProceed(user: user, type: type)
        if canProceed {
            if type == .anxiety { showSahay = true } else { showMochan = true }
        } else {
            alertMessage = "No trials are available for this assessment."
        }
    }

    private func assessmentCard(title: String, subtitle: String, systemImage: String, type: AssessmentType) -> some View {
        let trials = viewModel.remainingTrials(for: type)
        return VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage).font(.title).foregroundColor(MochanTheme.purple)
            Text(title).font(.headline).foregroundColor(MochanTheme.sageDark)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
            Text("Trials: \(trials)")
                .font(.caption2)
                .foregroundColor(MochanTheme.sage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mochanCard()
    }

    private func tool<Destination: View>(_ title: String, _ icon: String, _ destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(MochanTheme.purple)
                Text(title).font(.subheadline.bold()).foregroundColor(MochanTheme.sageDark)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .mochanCard()
        }
    }

    private var displayName: String {
        guard let name = auth.currentUser?.name, !name.isEmpty else { return "User" }
        return name
    }
}
