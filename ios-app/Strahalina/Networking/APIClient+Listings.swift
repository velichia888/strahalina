import Foundation

struct CreateListingBody: Encodable {
    let title: String
    let description: String
    let type: ListingType
    let priceCents: Int
    let location: String
    let keyFacts: [KeyFact]
}

extension APIClient {
    /// Public — no auth required. `status` is left nil for the normal
    /// public browse (server defaults to active-only); the admin
    /// listings screen passes an explicit status to see pending/sold too.
    func fetchListings(type: ListingType? = nil, status: ListingStatus? = nil, location: String? = nil) async throws -> [Listing] {
        let response: ListingsResponse = try await send(Endpoint(
            "/listings",
            query: ["type": type?.rawValue, "status": status?.rawValue, "location": location],
            requiresAuth: false
        ))
        return response.listings
    }

    func fetchListing(id: String) async throws -> Listing {
        let response: ListingResponse = try await send(Endpoint("/listings/\(id)", requiresAuth: false))
        return response.listing
    }

    func createListing(_ body: CreateListingBody) async throws -> Listing {
        let response: ListingResponse = try await send(Endpoint("/listings", method: .post, body: body))
        return response.listing
    }

    func updateListingStatus(id: String, status: ListingStatus) async throws -> Listing {
        struct Body: Encodable { let status: ListingStatus }
        let response: ListingResponse = try await send(Endpoint("/listings/\(id)", method: .patch, body: Body(status: status)))
        return response.listing
    }

    func deleteListing(id: String) async throws {
        try await sendNoContent(Endpoint("/listings/\(id)", method: .delete))
    }

    func uploadListingPhoto(listingId: String, imageData: Data, filename: String, mimeType: String) async throws -> ListingPhoto {
        let response: ListingPhotoResponse = try await sendMultipart(
            path: "/listings/\(listingId)/photos",
            files: [(fieldName: "photo", filename: filename, mimeType: mimeType, data: imageData)]
        )
        return response.photo
    }

    func deleteListingPhoto(listingId: String, photoId: String) async throws {
        try await sendNoContent(Endpoint("/listings/\(listingId)/photos/\(photoId)", method: .delete))
    }
}
