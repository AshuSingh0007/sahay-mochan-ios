import SwiftUI
import Combine

struct MochanAssessmentView: View {
    @StateObject private var viewModel = MochanViewModel()

    var body: some View {
        VStack(spacing: 18) {
            Text("Mochan Depression Assessment")
                .font(.title2.bold())
                .foregroundColor(MochanTheme.sageDark)
            Text("Complete a brief camera-supported PHQ-9 screening with the Mochan sage and purple care theme.")
                .foregroundColor(.secondary)
            NavigationLink("Start Camera Step") { MochanCameraView(viewModel: viewModel) }
                .mochanButton()
        }
        .padding()
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Mochan")
    }
}
