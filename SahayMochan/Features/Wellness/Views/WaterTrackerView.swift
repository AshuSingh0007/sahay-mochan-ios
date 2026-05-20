import SwiftUI
import Combine

struct WaterTrackerView: View {
    @StateObject private var viewModel = WaterViewModel()

    var body: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8).stroke(MochanTheme.sageDark, lineWidth: 2).frame(width: 140, height: 260)
                RoundedRectangle(cornerRadius: 8).fill(MochanTheme.purple.opacity(0.55)).frame(width: 136, height: 256 * viewModel.progress)
            }
            Text("\(viewModel.consumedML) / \(viewModel.goalML) ml").font(.title3.bold()).foregroundColor(MochanTheme.sageDark)
            HStack { Button("+250 ml") { viewModel.add(250) }; Button("+500 ml") { viewModel.add(500) }; Button("Reset") { viewModel.reset() } }
                .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Water")
    }
}
