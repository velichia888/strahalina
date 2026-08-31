import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView {
            BrowseFeedView()
                .tabItem { Label("Browse", systemImage: "house") }

            UpdatesFeedView()
                .tabItem { Label("Updates", systemImage: "megaphone") }

            // Shown to any signed-in user: buyers see their own threads,
            // admins see every conversation (GET /conversations already
            // returns the role-appropriate set).
            if session.status == .authenticated {
                InboxView()
                    .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }
            }

            if session.currentUser?.isAdmin == true {
                AdminListingsView()
                    .tabItem { Label("My Listings", systemImage: "list.bullet.rectangle") }
            }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
