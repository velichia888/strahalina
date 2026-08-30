import SwiftUI

/// Unlike the other apps, there's no separate signed-out auth gate at
/// the root — public browsing is always available. MainTabView itself
/// decides whether to show the admin-only tabs based on
/// session.currentUser?.isAdmin.
struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        Group {
            if session.status == .checking {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.canvas.ignoresSafeArea())
            } else {
                MainTabView()
            }
        }
    }
}
