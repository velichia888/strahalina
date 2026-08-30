import Foundation

extension APIClient {
    func signup(email: String, password: String, displayName: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password, displayName: String }
        return try await send(Endpoint("/auth/signup", method: .post, body: Body(email: email, password: password, displayName: displayName), requiresAuth: false))
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password: String }
        return try await send(Endpoint("/auth/login", method: .post, body: Body(email: email, password: password), requiresAuth: false))
    }

    func refresh(refreshToken: String) async throws -> TokenPairResponse {
        struct Body: Encodable { let refreshToken: String }
        return try await send(Endpoint("/auth/refresh", method: .post, body: Body(refreshToken: refreshToken), requiresAuth: false))
    }

    func fetchCurrentUser() async throws -> User {
        struct Response: Decodable { let user: User }
        let response: Response = try await send(Endpoint("/auth/me"))
        return response.user
    }

    func changePassword(currentPassword: String, newPassword: String) async throws -> TokenPairResponse {
        struct Body: Encodable { let currentPassword, newPassword: String }
        return try await send(Endpoint("/auth/change-password", method: .post, body: Body(currentPassword: currentPassword, newPassword: newPassword)))
    }

    func logout(accessToken: String) async throws {
        try await sendNoContent(Endpoint("/auth/logout", method: .post, overrideBearerToken: accessToken))
    }
}
