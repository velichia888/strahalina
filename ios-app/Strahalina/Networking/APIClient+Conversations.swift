import Foundation

// Real endpoints only — backend/src/routes/conversation.routes.ts.

extension APIClient {
    /// Starts (or continues) the caller's conversation on a listing with
    /// its first message. Buyer-only — an admin calling this is rejected
    /// server-side (400), since admins reply to existing conversations
    /// rather than starting new ones.
    func startConversation(listingId: String, message: String) async throws -> StartConversationResponse {
        struct Body: Encodable { let message: String }
        return try await send(Endpoint(
            "/listings/\(listingId)/conversations",
            method: .post,
            body: Body(message: message)
        ))
    }

    /// Buyers get only their own threads; admins get every conversation
    /// across every listing, since listings aren't individually owned.
    func fetchConversations() async throws -> [Conversation] {
        let response: ConversationsResponse = try await send(Endpoint("/conversations"))
        return response.conversations
    }

    func fetchMessages(conversationId: String) async throws -> [Message] {
        let response: MessagesResponse = try await send(Endpoint("/conversations/\(conversationId)/messages"))
        return response.messages
    }

    func sendMessage(conversationId: String, body: String) async throws -> Message {
        struct Body: Encodable { let body: String }
        let response: MessageResponse = try await send(Endpoint(
            "/conversations/\(conversationId)/messages",
            method: .post,
            body: Body(body: body)
        ))
        return response.message
    }

    func markConversationRead(conversationId: String) async throws {
        let _: EmptyOkResponse = try await send(Endpoint("/conversations/\(conversationId)/read", method: .post))
    }
}

private struct EmptyOkResponse: Decodable {
    let ok: Bool
}
