import SwiftUI

struct ListingCardView: View {
    let listing: Listing

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                photo
                StatusPill(status: listing.status)
                    .padding(Theme.Spacing.xs)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(Theme.Font.body(15).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(listing.location)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                Text(listing.priceDisplay)
                    .font(Theme.Font.body(14).weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 2)
        }
        .padding(Theme.Spacing.xs)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var photo: some View {
        if let first = listing.photos.first, let url = URL(string: first.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(4 / 3, contentMode: .fill)
                default:
                    placeholder
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
            .clipped()
        } else {
            placeholder
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Theme.borderSubtle)
            .overlay(
                Image(systemName: listing.type == .investment ? "chart.line.uptrend.xyaxis" : "house.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.inkFaint)
            )
    }
}

struct StatusPill: View {
    let status: ListingStatus

    var body: some View {
        Text(status.displayName)
            .font(Theme.Font.body(11).weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .foregroundStyle(Theme.statusColor(for: status))
            .clipShape(Capsule())
    }
}
