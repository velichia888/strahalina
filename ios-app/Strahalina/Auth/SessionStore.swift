import Foundation

enum SessionStoreError: LocalizedError {
    case keychainWriteFailed

    var errorDescription: String? {
        "Couldn't securely save your session on this device. Please try again."
    }
}

/// Single source of truth for auth/session state. Public browsing
/// (listings, updates) never needs this — only submitting an inquiry,
/// or the admin's listing/update-management screens, require a session.
@MainActor
final class SessionStore: ObservableObject {
    enum Status: Equatable {
        case checking
        case authenticated
        case unauthenticated
    }

    @Published private(set) var status: Status
    @Published private(set) var currentUser: User?
    @Published var sessionMessage: String?

    let apiClient: APIClient
    private var accessToken: String?
    private var sessionGeneration = 0

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        let hasStoredSession = KeychainStore.get(.accessToken) != nil && KeychainStore.get(.refreshToken) != nil
        self.accessToken = KeychainStore.get(.accessToken)
        self.status = hasStoredSession ? .checking : .unauthenticated
        self.apiClient.authDelegate = self
    }

    func restoreSession() async {
        guard status == .checking else { return }
        do {
            let user = try await apiClient.fetchCurrentUser()
            currentUser = user
            status = .authenticated
        } catch {
            clearStoredSession()
            status = .unauthenticated
        }
    }

    func signup(email: String, password: String, displayName: String) async throws {
        let response = try await apiClient.signup(email: email, password: password, displayName: displayName)
        try applyAuthenticatedSession(user: response.user, accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    func login(email: String, password: String) async throws {
        let response = try await apiClient.login(email: email, password: password)
        try applyAuthenticatedSession(user: response.user, accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let response = try await apiClient.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        sessionGeneration += 1
        guard KeychainStore.set(response.accessToken, for: .accessToken),
              KeychainStore.set(response.refreshToken, for: .refreshToken) else {
            throw SessionStoreError.keychainWriteFailed
        }
        accessToken = response.accessToken
    }

    func logout() {
        sessionGeneration += 1
        if let tokenToRevoke = accessToken {
            Task { [apiClient] in
                try? await apiClient.logout(accessToken: tokenToRevoke)
            }
        }
        clearStoredSession()
        status = .unauthenticated
    }

    func clearSessionMessage() {
        sessionMessage = nil
    }

    private func applyAuthenticatedSession(user: User, accessToken: String, refreshToken: String) throws {
        sessionGeneration += 1
        guard KeychainStore.set(accessToken, for: .accessToken) else {
            throw SessionStoreError.keychainWriteFailed
        }
        guard KeychainStore.set(refreshToken, for: .refreshToken) else {
            KeychainStore.delete(.accessToken)
            throw SessionStoreError.keychainWriteFailed
        }
        self.accessToken = accessToken
        self.currentUser = user
        status = .authenticated
        sessionMessage = nil
    }

    private func clearStoredSession() {
        accessToken = nil
        currentUser = nil
        KeychainStore.clearAll()
    }
}

#if DEBUG
extension SessionStore {
    /// CI-only — see MyEmptyCloset's identical helper for why Codemagic's
    /// cloud simulator can't complete a normal Keychain-backed login.
    func loginForCIScreenshotOnly(email: String, password: String) async throws {
        let response = try await apiClient.login(email: email, password: password)
        sessionGeneration += 1
        accessToken = response.accessToken
        currentUser = response.user
        status = .authenticated
        sessionMessage = nil
    }
}
#endif

extension SessionStore: APIAuthDelegate {
    var currentAccessToken: String? { accessToken }

    func refreshAccessToken() async throws -> String {
        let generation = sessionGeneration
        guard let refreshToken = KeychainStore.get(.refreshToken) else {
            throw APIError.sessionExpired
        }
        let response = try await apiClient.refresh(refreshToken: refreshToken)
        guard generation == sessionGeneration else {
            throw APIError.sessionExpired
        }
        guard KeychainStore.set(response.accessToken, for: .accessToken),
              KeychainStore.set(response.refreshToken, for: .refreshToken) else {
            throw SessionStoreError.keychainWriteFailed
        }
        accessToken = response.accessToken
        return response.accessToken
    }

    func handleSessionExpired() async {
        sessionGeneration += 1
        clearStoredSession()
        status = .unauthenticated
        sessionMessage = "Your session has expired. Please log in again."
    }
}
