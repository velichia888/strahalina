import SwiftUI

/// The public showcase — no auth required. Filters by listing type only
/// for this first pass (price-range filtering exists server-side but
/// isn't exposed in the UI yet).
struct BrowseFeedView: View {
    @EnvironmentObject private var session: SessionStore

    @State private var state: LoadState<[Listing]> = .loading
    @State private var typeFilter: ListingType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header

                    filterRow

                    content
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Strahalina")
            .navigationDestination(for: ListingRoute.self) { route in
                ListingDetailView(listingId: route.id)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Properties & Investments")
                .font(Theme.Font.headline(22))
                .foregroundStyle(Theme.ink)
            Text("Curated listings from Strahalina.")
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var filterRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            filterChip(title: "All", isSelected: typeFilter == nil) { typeFilter = nil }
            filterChip(title: "Property", isSelected: typeFilter == .property) { typeFilter = .property }
            filterChip(title: "Investment", isSelected: typeFilter == .investment) { typeFilter = .investment }
        }
        .onChange(of: typeFilter) { _ in
            Task { await load() }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.body(13).weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.ink : Theme.surface)
                .foregroundStyle(isSelected ? Theme.canvas : Theme.ink)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            LoadingStateView(label: "Loading listings…")
        case .failed(let error):
            ErrorStateView(error: error) { Task { await load() } }
        case .loaded(let listings):
            if listings.isEmpty {
                EmptyStateView(title: "No listings yet", message: "Check back soon.", systemImage: "house")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(listings) { listing in
                        NavigationLink(value: ListingRoute(id: listing.id)) {
                            ListingCardView(listing: listing)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func load() async {
        state = .loading
        do {
            let listings = try await session.apiClient.fetchListings(type: typeFilter)
            state = .loaded(listings)
        } catch {
            state = .failed(error)
        }
    }
}

#Preview {
    BrowseFeedView().environmentObject(SessionStore())
}
