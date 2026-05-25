import SwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome, \(displayName)")
                        .font(.title2.bold())
                        .foregroundColor(MochanTheme.sageDark)
                    HStack(spacing: 12) {
                        NavigationLink { SahayAssessmentView() } label: { assessmentCard(title: "Sahay", subtitle: "GAD-7 anxiety", systemImage: "waveform.path.ecg", trials: viewModel.anxietyTrials?.remainingTrials) }
                        NavigationLink { MochanAssessmentView() } label: { assessmentCard(title: "Mochan", subtitle: "PHQ-9 depression", systemImage: "heart.text.square", trials: viewModel.depressionTrials?.remainingTrials) }
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
        }
        .task { if let user = auth.currentUser { await viewModel.refreshTrials(for: user) } }
    }

    private func assessmentCard(title: String, subtitle: String, systemImage: String, trials: Int?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage).font(.title).foregroundColor(MochanTheme.purple)
            Text(title).font(.headline).foregroundColor(MochanTheme.sageDark)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
            Text("Trials: \(trials.map(String.init) ?? "--")").font(.caption2).foregroundColor(MochanTheme.sage)
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
        guard let name = auth.currentUser?.name, !name.isEmpty else { return "SahayMochan User" }
        return name
    }
}
