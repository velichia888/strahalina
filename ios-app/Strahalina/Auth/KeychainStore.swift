import Foundation
import Security

/// Minimal wrapper around the Keychain Services API for storing the two
/// auth tokens. No third-party dependency — the Security framework is
/// part of the platform. Tokens are the only thing ever written here; the
/// user's password is never persisted anywhere.
enum KeychainStore {
    private static let service = "com.strahalina.app.auth"

    enum Key: String {
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
    }

    /// Returns whether the write actually succeeded. Callers that treat a
    /// token as durably saved (rather than just held in memory for the
    /// current process) need to know when it was not — a discarded
    /// failure here would mean the app believes a token was persisted
    /// when it was not, only to silently sign the user out on next launch
    /// with no error ever surfaced.
    @discardableResult
    static func set(_ value: String, for key: Key) -> Bool {
        let data = Data(value.utf8)
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
        ]

        // Keychain items are update-or-insert, not upsert-by-default —
        // delete any existing item for this key first so re-login (or a
        // refreshed access token) cleanly replaces the old value rather
        // than erroring with errSecDuplicateItem.
        SecItemDelete(query as CFDictionary)

        query[kSecValueData] = data
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainStore.set failed for \(key.rawValue): OSStatus \(status)")
        }
        return status == errSecSuccess
    }

    static func get(_ key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: Key) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clearAll() {
        delete(.accessToken)
        delete(.refreshToken)
    }
}
