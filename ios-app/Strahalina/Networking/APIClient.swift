import Foundation

/// Lets APIClient read the current access token and trigger a refresh
/// without owning session/Keychain state itself — SessionStore conforms
/// to this. Avoids a retain cycle: APIClient holds this delegate weakly.
@MainActor
protocol APIAuthDelegate: AnyObject {
    var currentAccessToken: String? { get }
    /// Performs a real POST /auth/refresh call and returns the new access
    /// token, or throws if the refresh token is itself invalid/expired.
    func refreshAccessToken() async throws -> String
    /// Called once a refresh attempt has genuinely failed — the delegate
    /// is responsible for clearing the session and returning the user to
    /// the login screen.
    func handleSessionExpired() async
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Thin, real HTTP client for the MyEmptyCloset backend. Every network
/// call in this app goes through here (directly, or via the
/// feature-scoped extensions in this folder), so token injection,
/// 401-refresh-and-retry, and error-shape parsing are consistent
/// everywhere.
///
/// An actor, not a plain class: refreshAccessTokenCoalesced() below does
/// a check-then-set on `refreshTask` with no `await` in between, which is
/// only race-free if the whole method body can't interleave with another
/// concurrent call to it. Actor isolation serializes every call into this
/// type.
actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    /// nonisolated(unsafe), unlike `refreshTask` below: this is set
    /// exactly once, synchronously, by SessionStore.init() right after
    /// constructing both objects — before either is used — and never
    /// mutated again.
    nonisolated(unsafe) weak var authDelegate: APIAuthDelegate?

    /// Set once per process to avoid two concurrent requests each
    /// independently triggering their own refresh call when an access
    /// token expires mid-session.
    private var refreshTask: Task<String, Error>?

    /// Not a short default: Render's free-tier backend sleeps after 15
    /// minutes idle and can take up to roughly a minute to wake (Render's
    /// own docs don't guarantee an upper bound). A generous timeout means
    /// a real wake-up doesn't get misread as a network failure — see
    /// APIError.timeout.
    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 90
        return URLSession(configuration: configuration)
    }()

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = APIClient.defaultSession) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Shared Codable configuration

    /// The backend (Prisma) serializes DateTime as ISO-8601 with
    /// millisecond fractional seconds (e.g. "2026-08-30T06:34:17.976Z").
    /// Foundation's built-in `.iso8601` strategy does NOT parse fractional
    /// seconds by default, so every date in this app goes through a
    /// custom strategy that tries both forms.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFractional.date(from: raw) { return date }
            if let date = withoutFractional.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO-8601 date string, got \(raw)"
            )
        }
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Request description

    struct Endpoint {
        var path: String
        var method: HTTPMethod = .get
        var query: [String: String?] = [:]
        var body: Encodable? = nil
        /// Skip attaching the stored bearer token — only signup/login/
        /// refresh themselves need this.
        var requiresAuth: Bool = true
        /// Send this exact token instead of asking authDelegate for the
        /// current one. Only SessionStore.logout() uses this: it clears
        /// the stored access token synchronously and fires the
        /// server-side revocation call in the background, so by the time
        /// that call actually runs, authDelegate.currentAccessToken would
        /// already be nil.
        var overrideBearerToken: String? = nil

        init(
            _ path: String,
            method: HTTPMethod = .get,
            query: [String: String?] = [:],
            body: Encodable? = nil,
            requiresAuth: Bool = true,
            overrideBearerToken: String? = nil
        ) {
            self.path = path
            self.method = method
            self.query = query
            self.body = body
            self.requiresAuth = requiresAuth
            self.overrideBearerToken = overrideBearerToken
        }
    }

    /// Sends a multipart/form-data request (photo upload) expecting a
    /// decodable JSON response.
    func sendMultipart<T: Decodable>(
        path: String,
        fields: [String: String] = [:],
        files: [(fieldName: String, filename: String, mimeType: String, data: Data)]
    ) async throws -> T {
        let data = try await sendMultipartRaw(path: path, fields: fields, files: files)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    /// Sends a request expecting a decodable JSON response body.
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await sendRaw(endpoint)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    /// Sends a request with no response body expected (still validates
    /// the HTTP status).
    func sendNoContent(_ endpoint: Endpoint) async throws {
        _ = try await sendRaw(endpoint)
    }

    // MARK: - Core

    private func sendRaw(_ endpoint: Endpoint, isRetryAfterRefresh: Bool = false) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        let queryItems = endpoint.query.compactMap { key, value -> URLQueryItem? in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = endpoint.method.rawValue

        if let overrideToken = endpoint.overrideBearerToken {
            urlRequest.setValue("Bearer \(overrideToken)", forHTTPHeaderField: "Authorization")
        } else if endpoint.requiresAuth, let token = await authDelegate?.currentAccessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try Self.encoder.encode(AnyEncodable(body))
        }

        return try await performAndHandle(urlRequest, requiresAuth: endpoint.requiresAuth, isRetryAfterRefresh: isRetryAfterRefresh) {
            try await self.sendRaw(endpoint, isRetryAfterRefresh: true)
        }
    }

    private func sendMultipartRaw(
        path: String,
        fields: [String: String],
        files: [(fieldName: String, filename: String, mimeType: String, data: Data)],
        isRetryAfterRefresh: Bool = false
    ) async throws -> Data {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = HTTPMethod.post.rawValue
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = await authDelegate?.currentAccessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = body

        return try await performAndHandle(urlRequest, requiresAuth: true, isRetryAfterRefresh: isRetryAfterRefresh) {
            try await self.sendMultipartRaw(path: path, fields: fields, files: files, isRetryAfterRefresh: true)
        }
    }

    private func performAndHandle(
        _ urlRequest: URLRequest,
        requiresAuth: Bool,
        isRetryAfterRefresh: Bool,
        retry: () async throws -> Data
    ) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            if (error as? URLError)?.code == .timedOut {
                throw APIError.timeout
            }
            throw APIError.network(underlying: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.network(underlying: "No HTTP response")
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return data
        }

        // A 401 on an authenticated call: try exactly one refresh, then
        // retry the original call once. Never recurse past one retry.
        if httpResponse.statusCode == 401, requiresAuth, !isRetryAfterRefresh {
            do {
                _ = try await refreshAccessTokenCoalesced()
            } catch {
                await authDelegate?.handleSessionExpired()
                throw APIError.sessionExpired
            }

            do {
                return try await retry()
            } catch let retryError as APIError {
                if case .server(401, _) = retryError {
                    await authDelegate?.handleSessionExpired()
                    throw APIError.sessionExpired
                }
                throw retryError
            }
        }

        let message = (try? Self.decoder.decode(ServerErrorBody.self, from: data))?.error ?? ""
        throw APIError.server(status: httpResponse.statusCode, message: message)
    }

    /// Coalesces concurrent refresh attempts into a single in-flight
    /// task, so N requests that all hit a stale access token at once
    /// don't each fire their own POST /auth/refresh.
    private func refreshAccessTokenCoalesced() async throws -> String {
        if let existing = refreshTask {
            return try await existing.value
        }
        let task = Task<String, Error> {
            guard let delegate = authDelegate else {
                throw APIError.sessionExpired
            }
            return try await delegate.refreshAccessToken()
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}

private struct ServerErrorBody: Decodable {
    let error: String
}

/// Type-erasing wrapper so `Endpoint.body: Encodable?` can be encoded
/// without Swift's inability to call `encode(_:)` directly on an
/// existential `Encodable` value.
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
