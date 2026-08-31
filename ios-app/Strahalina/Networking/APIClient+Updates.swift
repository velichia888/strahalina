import Foundation

extension APIClient {
    /// `category: nil` returns every update (the "All" tab); a specific
    /// category filters to just that real, admin-tagged set.
    func fetchUpdates(category: UpdateCategory? = nil) async throws -> [Update] {
        let response: UpdatesResponse = try await send(Endpoint(
            "/updates",
            query: ["category": category?.rawValue],
            requiresAuth: false
        ))
        return response.updates
    }

    func createUpdate(
        body: String,
        listingId: String?,
        category: UpdateCategory = .general,
        externalVideoUrl: String? = nil,
        imageData: Data?,
        filename: String?,
        mimeType: String?
    ) async throws -> Update {
        var fields: [String: String] = ["body": body, "category": category.rawValue]
        if let listingId { fields["listingId"] = listingId }
        if let externalVideoUrl, !externalVideoUrl.isEmpty { fields["externalVideoUrl"] = externalVideoUrl }

        let files: [(fieldName: String, filename: String, mimeType: String, data: Data)]
        if let imageData, let filename, let mimeType {
            files = [(fieldName: "photo", filename: filename, mimeType: mimeType, data: imageData)]
        } else {
            files = []
        }

        let response: UpdateResponse = try await sendMultipart(path: "/updates", fields: fields, files: files)
        return response.update
    }

    func deleteUpdate(id: String) async throws {
        try await sendNoContent(Endpoint("/updates/\(id)", method: .delete))
    }
}
