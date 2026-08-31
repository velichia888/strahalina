import Foundation

/// Central, minimal app configuration. Only public, client-safe values
/// belong here — the API base URL and nothing else.
enum AppConfig {
    /// Not yet deployed — this app hasn't been pushed to Render, per the
    /// user's explicit "don't deploy yet" instruction for this pass.
    /// Points at a local backend for Simulator work against
    /// `npm run dev`. Swap to the real Render URL once deployed, same as
    /// every other app's AppConfig did after its own first deploy.
    static let apiBaseURL = URL(string: "http://localhost:4003")!

    enum Limits {
        static let listingTitleMax = 120
        static let listingDescriptionMax = 4000
        static let updateBodyMax = 2000
        static let messageBodyMax = 2000
        static let maxPhotosPerListing = 10
    }
}
