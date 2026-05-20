import SwiftUI
import Combine

struct SleepTrackerView: View {
    @StateObject private var viewModel = SleepViewModel()
    @State private var hours = 7.0
    @State private var quality = 3

    var body: some View {
        List {
            Section("Log Sleep") {
                Stepper("Hours: \(hours, specifier: "%.1f")", value: $hours, in: 0...16, step: 0.5)
                Stepper("Quality: \(quality)/5", value: $quality, in: 1...5)
                Button("Save") { viewModel.add(hours: hours, quality: quality) }
            }
            Section("Week") { MiniBarChart(values: viewModel.week.map { min(1, $0.hours / 10) }, color: MochanTheme.sage) }
        }
        .navigationTitle("Sleep")
    }
}
