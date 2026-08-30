import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView {
            BrowseFeedView()
                .tabItem { Label("Browse", systemImage: "house") }

            UpdatesFeedView()
                .tabItem { Label("Updates", systemImage: "megaphone") }

            if session.currentUser?.isAdmin == true {
                AdminListingsView()
                    .tabItem { Label("My Listings", systemImage: "list.bullet.rectangle") }

                InquiriesInboxView()
                    .tabItem { Label("Inquiries", systemImage: "tray") }
            }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
