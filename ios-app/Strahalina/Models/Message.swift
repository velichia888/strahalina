import Foundation

struct ConversationParty: Codable, Equatable {
    let id: String
    let displayName: String
    let email: String
}

struct ConversationListingRef: Codable, Equatable {
    let id: String
    let title: String
}

struct ConversationMessagePreview: Codable, Equatable {
    let id: String
    let body: String
    let senderId: String
    let createdAt: Date
    let readAt: Date?
}

/// One row from GET /conversations — backend/src/controllers/
/// conversation.controller.ts listConversations(). Buyers see only
/// their own threads; admins see every conversation across every
/// listing, since listings aren't individually owned.
struct Conversation: Codable, Identifiable, Equatable {
    let id: String
    let listingId: String
    let listing: ConversationListingRef?
    let buyer: ConversationParty?
    let createdAt: Date
    let updatedAt: Date
    let lastMessage: ConversationMessagePreview?
}

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String
    let createdAt: Date
    let readAt: Date?
}

struct ConversationsResponse: Decodable {
    let conversations: [Conversation]
}

struct MessagesResponse: Decodable {
    let messages: [Message]
}

struct StartConversationResponse: Decodable {
    let conversation: Conversation
    let message: Message
}

struct MessageResponse: Decodable {
    let message: Message
}
