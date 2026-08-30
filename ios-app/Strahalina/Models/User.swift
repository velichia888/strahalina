import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let isAdmin: Bool
    let createdAt: Date
}

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct TokenPairResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
