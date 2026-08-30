import Foundation

struct InquiryBuyer: Codable, Equatable {
    let id: String
    let displayName: String
    let email: String
}

struct InquiryListingRef: Codable, Equatable {
    let id: String
    let title: String
}

struct Inquiry: Codable, Identifiable, Equatable {
    let id: String
    let listingId: String
    let listing: InquiryListingRef?
    let message: String
    let respondedAt: Date?
    let createdAt: Date
    let buyer: InquiryBuyer
}

struct InquiriesResponse: Decodable {
    let inquiries: [Inquiry]
}

struct InquiryResponse: Decodable {
    let inquiry: Inquiry
}
