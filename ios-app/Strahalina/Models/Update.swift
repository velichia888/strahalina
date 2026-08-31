import Foundation

struct UpdateAuthor: Codable, Equatable {
    let id: String
    let displayName: String
}

/// Mirrors the backend's UpdateCategory enum. One real Updates feed,
/// tagged so the UI can offer the "Market Insights" / "Content Hub"
/// filter tabs from the mockup without a second, fabricated content
/// system.
enum UpdateCategory: String, Codable, CaseIterable {
    case general
    case marketInsight = "market_insight"
    case content

    var displayName: String {
        switch self {
        case .general: return "All"
        case .marketInsight: return "Market Insights"
        case .content: return "Content"
        }
    }
}

struct Update: Codable, Identifiable, Equatable {
    let id: String
    let body: String
    let externalVideoUrl: String?
    let category: UpdateCategory
    let listingId: String?
    let createdAt: Date
    let author: UpdateAuthor
    let photoUrl: String?
}

struct UpdatesResponse: Decodable {
    let updates: [Update]
}

struct UpdateResponse: Decodable {
    let update: Update
}
