import SwiftUI
import Combine

struct SahayAssessmentView: View {
    @StateObject private var viewModel = SahayViewModel()

    var body: some View {
        VStack(spacing: 18) {
            Text("Sahay Anxiety Assessment")
                .font(.title2.bold())
                .foregroundColor(MochanTheme.sageDark)
            Text("Complete a brief camera-supported GAD-7 screening. Choose the answer that best matches the last two weeks.")
                .foregroundColor(.secondary)
            NavigationLink("Start Camera Step") { SahayCameraView(viewModel: viewModel) }
                .mochanButton()
        }
        .padding()
        .background(MochanTheme.sageBackground.ignoresSafeArea())
        .navigationTitle("Sahay")
    }
}
