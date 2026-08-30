import Foundation

struct UpdateAuthor: Codable, Equatable {
    let id: String
    let displayName: String
}

struct Update: Codable, Identifiable, Equatable {
    let id: String
    let body: String
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
