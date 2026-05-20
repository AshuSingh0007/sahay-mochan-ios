import SwiftUI
import Combine

struct MoodTrackerView: View {
    @StateObject private var viewModel = MoodViewModel()
    @State private var emoji = "🙂"
    @State private var happiness = 0.6
    @State private var energy = 0.5
    private let emojis = ["😔", "😐", "🙂", "😊", "😄"]

    var body: some View {
        List {
            Section("Today") {
                Picker("Mood", selection: $emoji) { ForEach(emojis, id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
                Slider(value: $happiness, in: 0...1) { Text("Happiness") }
                Slider(value: $energy, in: 0...1) { Text("Energy") }
                Button("Log Mood") { viewModel.add(emoji: emoji, happiness: happiness, energy: energy) }
            }
            Section("30 Days") { MiniBarChart(values: viewModel.recent.map(\.happiness), color: MochanTheme.purple) }
        }
        .navigationTitle("Mood")
    }
}

struct MiniBarChart: View {
    let values: [Double]
    let color: Color
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 8, height: max(6, value * 100))
            }
        }
        .frame(height: 110, alignment: .bottom)
    }
}
