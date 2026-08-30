import Foundation

/// Every error shape this app's networking layer actually surfaces.
/// Deliberately not a single generic case — call sites (and the views
/// that render them) need to tell "you're offline," "your session
/// expired," and "the server rejected your input" apart.
enum APIError: Error, Equatable {
    /// The request never reached the server (no connectivity, backend
    /// not running, DNS failure, etc.) — no HTTP status exists.
    case network(underlying: String)

    /// The request timed out waiting for a response. Distinguished from
    /// `.network` because the most common real cause on this backend's
    /// free-tier hosting is a cold start (Render sleeps the service after
    /// 15 minutes idle and can take up to roughly a minute to wake) — not
    /// a real connectivity problem.
    case timeout

    /// A real HTTP response came back outside 200..<300. `message` is the
    /// backend's own `{"error": "..."}` body when present (every error
    /// response in this backend has that shape — see
    /// backend/src/middleware/errorHandler.ts), else a generic fallback.
    case server(status: Int, message: String)

    /// The response body didn't decode into the expected type — a real
    /// client/server contract mismatch, not a network or auth problem.
    case decoding(String)

    /// Session could not be refreshed and the user must log in again.
    case sessionExpired

    var status: Int? {
        if case .server(let status, _) = self { return status }
        return nil
    }

    var userMessage: String {
        switch self {
        case .network:
            return "Can't reach Strahalina. Check your connection and try again."
        case .timeout:
            return "Strahalina is waking up — this can take up to a minute after being idle. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .decoding:
            return "Something went wrong reading the server's response."
        case .server(let status, let message):
            switch status {
            case 401: return "Your session has expired. Please log in again."
            case 403: return message.isEmpty ? "You don't have permission to do that." : message
            case 404: return "That couldn't be found. It may have been removed."
            case 400, 409, 413, 415: return message.isEmpty ? "That request couldn't be completed." : message
            default: return message.isEmpty ? "Something went wrong (\(status))." : message
            }
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.network(let a), .network(let b)): return a == b
        case (.timeout, .timeout): return true
        case (.server(let sa, let ma), .server(let sb, let mb)): return sa == sb && ma == mb
        case (.decoding(let a), .decoding(let b)): return a == b
        case (.sessionExpired, .sessionExpired): return true
        default: return false
        }
    }
}
