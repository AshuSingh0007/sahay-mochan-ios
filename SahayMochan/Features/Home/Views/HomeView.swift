import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house") }
            AssessmentHistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .accentColor(MochanTheme.purple)
    }
}
