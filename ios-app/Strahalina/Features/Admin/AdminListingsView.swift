import SwiftUI

/// Admin-only listing management: sees every status (public browse
/// defaults to active-only), can change status or delete.
struct AdminListingsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<[Listing]> = .loading
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loading:
                    LoadingStateView(label: "Loading listings…")
                case .failed(let error):
                    ErrorStateView(error: error) { Task { await load() } }
                case .loaded(let listings):
                    if listings.isEmpty {
                        EmptyStateView(title: "No listings yet", systemImage: "house")
                    } else {
                        List {
                            ForEach(listings) { listing in
                                row(for: listing)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("My Listings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showingCreate, onDismiss: { Task { await load() } }) {
                CreateListingView().environmentObject(session)
            }
        }
    }

    private func row(for listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(listing.title).font(Theme.Font.body(15).weight(.semibold))
                Spacer()
                StatusPill(status: listing.status)
            }
            Text(listing.priceDisplay).font(Theme.Font.body(13)).foregroundStyle(Theme.accent)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(ListingStatus.allCases, id: \.self) { status in
                    if status != listing.status {
                        Button(status.displayName) {
                            Task { await setStatus(listing, status: status) }
                        }
                        .font(Theme.Font.body(12))
                        .buttonStyle(.bordered)
                    }
                }
                Spacer()
                Button(role: .destructive) {
                    Task { await delete(listing) }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func load() async {
        state = .loading
        do {
            // No status filter here so every status comes back — public
            // fetchListings() with no args defaults server-side to
            // active-only, which is wrong for this admin management view.
            var all: [Listing] = []
            for status in ListingStatus.allCases {
                all += try await session.apiClient.fetchListings(status: status)
            }
            state = .loaded(all.sorted { $0.createdAt > $1.createdAt })
        } catch {
            state = .failed(error)
        }
    }

    private func setStatus(_ listing: Listing, status: ListingStatus) async {
        _ = try? await session.apiClient.updateListingStatus(id: listing.id, status: status)
        await load()
    }

    private func delete(_ listing: Listing) async {
        try? await session.apiClient.deleteListing(id: listing.id)
        await load()
    }
}
