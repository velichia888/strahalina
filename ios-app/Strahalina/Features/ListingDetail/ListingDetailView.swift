import SwiftUI

struct ListingDetailView: View {
    let listingId: String

    @EnvironmentObject private var session: SessionStore
    @State private var state: LoadState<Listing> = .loading
    @State private var showingAuth = false
    @State private var showingCompose = false
    @State private var startedConversation: Conversation?

    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                LoadingStateView(label: "Loading listing…")
            case .failed(let error):
                ErrorStateView(error: error) { Task { await load() } }
            case .loaded(let listing):
                content(for: listing)
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showingAuth) {
            AuthFlowView().environmentObject(session)
        }
        .sheet(isPresented: $showingCompose) {
            if case .loaded(let listing) = state {
                MessageComposeView(listing: listing) { conversation in
                    startedConversation = conversation
                }
                .environmentObject(session)
            }
        }
        .background(conversationNavigationLink)
    }

    // Programmatic push driven by an optional @State value needs
    // `navigationDestination(item:)`, which is iOS 17+ only — this
    // app's deployment target is 16.0, so this uses the older
    // isActive-driven NavigationLink instead.
    private var conversationNavigationLink: some View {
        NavigationLink(
            destination: Group {
                if let startedConversation {
                    ConversationDetailView(conversation: startedConversation).environmentObject(session)
                }
            },
            isActive: Binding(
                get: { startedConversation != nil },
                set: { isActive in if !isActive { startedConversation = nil } }
            )
        ) { EmptyView() }
    }

    @ViewBuilder
    private func content(for listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            photoCarousel(listing.photos)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(listing.title)
                        .font(Theme.Font.headline(22))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    StatusPill(status: listing.status)
                }
                Text(listing.location)
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.inkSoft)
                Text(listing.priceDisplay)
                    .font(Theme.Font.body(22).weight(.bold))
                    .foregroundStyle(Theme.accent)
            }

            if !listing.keyFacts.isEmpty {
                keyFactsGrid(listing.keyFacts)
            }

            Text(listing.description)
                .font(Theme.Font.body(15))
                .foregroundStyle(Theme.ink)

            Text("Figures above are provided by the listing owner, not independently verified.")
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.inkFaint)

            // Admins manage every listing jointly rather than owning
            // this one individually, so "message about this listing"
            // isn't a real action for them — the backend rejects an
            // admin trying to start a conversation (400).
            if session.currentUser?.isAdmin != true {
                Button("Request Details") {
                    if session.status == .authenticated {
                        showingCompose = true
                    } else {
                        showingAuth = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(Theme.Spacing.md)
    }

    @ViewBuilder
    private func photoCarousel(_ photos: [ListingPhoto]) -> some View {
        if photos.isEmpty {
            Rectangle()
                .fill(Theme.borderSubtle)
                .frame(height: 240)
                .overlay(Image(systemName: "house.fill").font(.system(size: 40)).foregroundStyle(Theme.inkFaint))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        } else {
            TabView {
                ForEach(photos) { photo in
                    if let url = URL(string: photo.url) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(Theme.borderSubtle)
                            }
                        }
                        .clipped()
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }

    private func keyFactsGrid(_ facts: [KeyFact]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                HStack {
                    Text(fact.label)
                        .font(Theme.Font.body(14))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(fact.value)
                        .font(Theme.Font.body(14).weight(.semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.vertical, Theme.Spacing.xs)
                if index < facts.count - 1 {
                    Divider()
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }

    private func load() async {
        state = .loading
        do {
            let listing = try await session.apiClient.fetchListing(id: listingId)
            state = .loaded(listing)
        } catch {
            state = .failed(error)
        }
    }
}
