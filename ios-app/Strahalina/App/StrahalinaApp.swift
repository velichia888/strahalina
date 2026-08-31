import SwiftUI
import UIKit

@main
struct StrahalinaApp: App {
    @StateObject private var session = SessionStore()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.canvas)
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.ink)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.ink)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        let tabItemAppearance = UITabBarItemAppearance()
        tabItemAppearance.normal.iconColor = UIColor(Theme.inkFaint)
        tabItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.inkFaint)]
        tabItemAppearance.selected.iconColor = UIColor(Theme.accent)
        tabItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.accent)]

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.surface)
        tabAppearance.stackedLayoutAppearance = tabItemAppearance
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(Theme.accent)
                // The mockups are entirely dark-themed (near-black canvas,
                // gold accent, cream text) — force dark system chrome
                // (status bar text, keyboard, alerts) to match rather
                // than following the device's own light/dark setting.
                .preferredColorScheme(.dark)
                .task {
                    await session.restoreSession()

                    #if DEBUG
                    // CI-only autologin for Codemagic's simulator workflow
                    // — see the identical pattern in myemptycloset/Car
                    // Hopping's App entry files for why this exists
                    // (Codemagic's cloud simulator can't write to
                    // Keychain at all).
                    let environment = ProcessInfo.processInfo.environment
                    if environment["IOS_TEST_AUTOMATION"] == "1" {
                        print("IOS_TEST_APP_LAUNCHED")
                        if session.status == .unauthenticated,
                           let email = environment["IOS_TEST_EMAIL"],
                           let password = environment["IOS_TEST_PASSWORD"],
                           !email.isEmpty, !password.isEmpty {
                            do {
                                try await session.login(email: email, password: password)
                                print("IOS_TEST_AUTOLOGIN_SUCCESS")
                            } catch SessionStoreError.keychainWriteFailed {
                                do {
                                    try await session.loginForCIScreenshotOnly(email: email, password: password)
                                    print("IOS_TEST_AUTOLOGIN_SUCCESS (in-memory only - Keychain unavailable in this CI environment)")
                                } catch {
                                    print("IOS_TEST_AUTOLOGIN_FAILED: \(String(describing: error))")
                                }
                            } catch {
                                print("IOS_TEST_AUTOLOGIN_FAILED: \(String(describing: error))")
                            }
                        }
                    }
                    #endif
                }
        }
    }
}
