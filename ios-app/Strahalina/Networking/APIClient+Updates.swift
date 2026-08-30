import Foundation

extension APIClient {
    func fetchUpdates() async throws -> [Update] {
        let response: UpdatesResponse = try await send(Endpoint("/updates", requiresAuth: false))
        return response.updates
    }

    func createUpdate(body: String, listingId: String?, imageData: Data?, filename: String?, mimeType: String?) async throws -> Update {
        var fields: [String: String] = ["body": body]
        if let listingId { fields["listingId"] = listingId }

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
