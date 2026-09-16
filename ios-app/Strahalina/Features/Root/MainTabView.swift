import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(0)
                .tabItem { Label("Home", systemImage: "house.fill") }

            BrowseFeedView()
                .tag(1)
                .tabItem { Label("Browse", systemImage: "square.grid.2x2") }

            UpdatesFeedView()
                .tag(2)
                .tabItem { Label("Updates", systemImage: "megaphone") }

            // Shown to any signed-in user: buyers see their own threads,
            // admins see every conversation (GET /conversations already
            // returns the role-appropriate set).
            if session.status == .authenticated {
                InboxView()
                    .tag(3)
                    .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }
            }

            if session.currentUser?.isAdmin == true {
                AdminListingsView()
                    .tag(4)
                    .tabItem { Label("My Listings", systemImage: "list.bullet.rectangle") }
            }

            ProfileView()
                .tag(5)
                .tabItem { Label("Profile", systemImage: "person") }
        }
        #if DEBUG
        .task {
            // Drives a self-contained screenshot tour for the
            // ios-simulator CI workflow only (IOS_TEST_AUTOMATION is
            // never set for the real App Store build). Prints a log
            // marker per tab, same pattern as StrahalinaApp's autologin,
            // so the CI script can grep-wait for each one instead of
            // guessing sleep durations against variable data-load timing.
            guard ProcessInfo.processInfo.environment["IOS_TEST_AUTOMATION"] == "1" else { return }

            // This task starts as soon as MainTabView first appears, which
            // happens right after restoreSession() resolves (fast, no
            // stored session in CI) - well before StrahalinaApp's separate
            // autologin .task actually finishes its network call. A fixed
            // sleep here raced that: CI's own wait for
            // IOS_TEST_AUTOLOGIN_SUCCESS routinely took longer than this
            // sleep, so by the time CI checked for IOS_TEST_TAB_HOME the
            // marker had already been printed (and superseded by a later
            // selection change) seconds earlier - every screenshot landed
            // one tab ahead of its own marker. Waiting for login to
            // actually settle first anchors the tour to when it really
            // happens instead of a guess from launch.
            var waited = 0.0
            while session.status == .unauthenticated && waited < 15 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                waited += 0.2
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            print("IOS_TEST_TAB_HOME")

            selection = 1
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            print("IOS_TEST_TAB_BROWSE")

            selection = 2
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            print("IOS_TEST_TAB_UPDATES")

            selection = session.status == .authenticated ? 3 : 5
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            print(session.status == .authenticated ? "IOS_TEST_TAB_MESSAGES" : "IOS_TEST_TAB_PROFILE")
        }
        #endif
    }
}
