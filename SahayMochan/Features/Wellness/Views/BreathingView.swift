import SwiftUI
import Combine

struct BreathingView: View {
    @StateObject private var viewModel = BreathingViewModel()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Circle()
                .fill(MochanTheme.purpleGradient)
                .frame(width: viewModel.phase == .inhale ? 220 : 150, height: viewModel.phase == .inhale ? 220 : 150)
                .overlay(Text("\(viewModel.secondsRemaining)").font(.largeTitle.bold()).foregroundColor(.white))
                .animation(.easeInOut(duration: 1), value: viewModel.phase)
            Text(viewModel.phase.rawValue).font(.title2.bold()).foregroundColor(MochanTheme.sageDark)
            Button(viewModel.isRunning ? "Stop" : "Start 4-7-8") { viewModel.isRunning ? viewModel.stop() : viewModel.start() }.mochanButton()
            Spacer()
        }
        .padding()
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Breathing")
    }
}
