import Foundation

enum ListingType: String, Codable, CaseIterable {
    case property
    case investment

    var displayName: String {
        switch self {
        case .property: return "Property"
        case .investment: return "Investment"
        }
    }
}

enum ListingStatus: String, Codable, CaseIterable {
    case active
    case pending
    case sold

    var displayName: String {
        rawValue.capitalized
    }
}

struct KeyFact: Codable, Identifiable, Equatable {
    var id: String { label }
    let label: String
    let value: String
}

struct ListingPhoto: Codable, Identifiable, Equatable {
    let id: String
    let url: String
}

struct Listing: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let type: ListingType
    let status: ListingStatus
    let priceCents: Int
    let location: String
    let keyFacts: [KeyFact]
    let createdAt: Date
    let updatedAt: Date
    let photos: [ListingPhoto]

    var priceDisplay: String {
        let dollars = Double(priceCents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(Int(dollars))"
    }
}

struct ListingsResponse: Decodable {
    let listings: [Listing]
}

struct ListingResponse: Decodable {
    let listing: Listing
}

struct ListingPhotoResponse: Decodable {
    let photo: ListingPhoto
}
