import Foundation

/// Mirrors the backend's ConversationKind enum. `.listing` conversations
/// are tied to one property/investment; `.consultation` and
/// `.investorInquiry` are general threads started from the "Book a
/// Consultation" / "Investor Inquiry" forms — same real
/// Conversation/Message system, just unattached to a listing.
enum ConversationKind: String, Codable {
    case listing
    case consultation
    case investorInquiry = "investor_inquiry"

    var displayTitle: String {
        switch self {
        case .listing: return "Listing"
        case .consultation: return "Consultation Request"
        case .investorInquiry: return "Investor Inquiry"
        }
    }
}

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
    let kind: ConversationKind
    // Optional: general consultation/investor-inquiry threads aren't
    // tied to any listing.
    let listingId: String?
    let listing: ConversationListingRef?
    let buyer: ConversationParty?
    let createdAt: Date
    let updatedAt: Date
    let lastMessage: ConversationMessagePreview?

    /// What to show in the Inbox row / navigation title when there's no
    /// listing to name (general consultation/investor-inquiry threads).
    var displayTitle: String {
        listing?.title ?? kind.displayTitle
    }
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
