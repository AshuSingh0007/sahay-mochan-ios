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
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
        .background(MochanTheme.sageBackground.ignoresSafeArea())
    }
}
