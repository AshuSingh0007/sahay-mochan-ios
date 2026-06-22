import SwiftUI
import Combine

@main
struct SahayMochanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.role == .clinician {
                    ClinicianDashboardView()
                } else {
                    HomeView()
                }
            } else {
                LoginView()
            }
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
    }
}
