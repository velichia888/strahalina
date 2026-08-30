import Foundation

extension APIClient {
    /// Requires a signed-in user (any account, not just admin) — see
    /// backend/src/routes/inquiry.routes.ts.
    func submitInquiry(listingId: String, message: String) async throws -> Inquiry {
        struct Body: Encodable { let message: String }
        let response: InquiryResponse = try await send(Endpoint("/listings/\(listingId)/inquiries", method: .post, body: Body(message: message)))
        return response.inquiry
    }

    /// Admin-only inbox.
    func fetchInquiries() async throws -> [Inquiry] {
        let response: InquiriesResponse = try await send(Endpoint("/inquiries"))
        return response.inquiries
    }

    func respondToInquiry(id: String) async throws -> Inquiry {
        let response: InquiryResponse = try await send(Endpoint("/inquiries/\(id)/respond", method: .post))
        return response.inquiry
    }
}
