import Foundation

/// Central, minimal app configuration. Only public, client-safe values
/// belong here — the API base URL and nothing else.
enum AppConfig {
    // Render assigned this exact hostname (not the plain "strahalina-backend"
    // in render.yaml's `name:` field) since a service with that base name
    // already existed when this one was first created manually — a second,
    // identically-named "strahalina-backend" service also exists from a
    // later Blueprint sync attempt, but it never deployed successfully.
    // This one is the real, live backend.
    static let apiBaseURL = URL(string: "https://strahalina-backend-2tpe.onrender.com")!

    enum Limits {
        static let listingTitleMax = 120
        static let listingDescriptionMax = 4000
        static let updateBodyMax = 2000
        static let messageBodyMax = 2000
        static let maxPhotosPerListing = 10
    }
}
