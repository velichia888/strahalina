import SwiftUI

/// The mockup's single-page marketing site, adapted to a native
/// scrollable Home tab: hero, real listing previews, the three
/// promo cards, and CTAs into the real consultation/inquiry forms.
/// Every preview section pulls real data (or shows a real empty
/// state) — nothing here is a fabricated example.
struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var propertiesState: LoadState<[Listing]> = .loading
    @State private var investmentsState: LoadState<[Listing]> = .loading

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    hero
                    previewSection(
                        eyebrow: "PROPERTIES",
                        title: "Exceptional properties, extraordinary lifestyles.",
                        state: propertiesState,
                        viewAllFilter: .property
                    )
                    previewSection(
                        eyebrow: "INVESTMENTS",
                        title: "Curated deals, strategic returns.",
                        state: investmentsState,
                        viewAllFilter: .investment
                    )
                    promoRow
                    aboutPreview
                    marketInsightsLink
                    consultationCTA
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Strahalina")
            .navigationDestination(for: ListingRoute.self) { route in
                ListingDetailView(listingId: route.id)
            }
            .task { await loadPreviews() }
            .refreshable { await loadPreviews() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("PROPERTIES · CAPITAL · CONNECTIONS · LEGACY")
                .font(Theme.Font.eyebrow(11))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text("Building wealth through real estate and relationships.")
                .font(Theme.Font.headline(24))
                .foregroundStyle(Theme.ink)

            HStack(spacing: Theme.Spacing.sm) {
                brandBadge(name: "THE ONE ENTERPRISES", tagline: "Real Estate · Brokerage · Development")
                brandBadge(name: "MURADYAN GROUP CAPITAL", tagline: "Invest · Grow · Legacy")
            }
        }
    }

    private func brandBadge(name: String, tagline: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(Theme.Font.body(11).weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(tagline)
                .font(Theme.Font.body(9))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }

    @ViewBuilder
    private func previewSection(eyebrow: String, title: String, state: LoadState<[Listing]>, viewAllFilter: ListingType) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(Theme.Font.eyebrow(11))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text(title)
                        .font(Theme.Font.headline(16))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                NavigationLink("View All") { BrowseFeedView(initialTypeFilter: viewAllFilter) }
                    .font(Theme.Font.body(12).weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            switch state {
            case .loading:
                LoadingStateView(label: "Loading…")
            case .failed:
                EmptyView()
            case .loaded(let listings):
                if listings.isEmpty {
                    EmptyStateView(title: "None listed yet", message: "Check back soon.", systemImage: "house")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(listings) { listing in
                                NavigationLink(value: ListingRoute(id: listing.id)) {
                                    ListingCardView(listing: listing)
                                        .frame(width: 180)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var promoRow: some View {
        VStack(spacing: Theme.Spacing.sm) {
            NavigationLink { PromoInfoView.forBuyers } label: { promoCard(PromoInfoView.forBuyers) }
            NavigationLink { PromoInfoView.forSellers } label: { promoCard(PromoInfoView.forSellers) }
            NavigationLink { PromoInfoView.forInvestors } label: { promoCard(PromoInfoView.forInvestors) }
        }
    }

    private func promoCard(_ promo: PromoInfoView) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: promo.icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(promo.title)
                    .font(Theme.Font.body(15).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(promo.pitch)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).stroke(Theme.borderSubtle, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private var aboutPreview: some View {
        NavigationLink { AboutView() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ABOUT US")
                        .font(Theme.Font.eyebrow(11))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text("A partnership built on trust, vision, and execution.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var marketInsightsLink: some View {
        NavigationLink { UpdatesFeedView(initialCategory: .marketInsight) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MARKET INSIGHTS")
                        .font(Theme.Font.eyebrow(11))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text("Knowledge. Analysis. Advantage.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var consultationCTA: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("LET'S BUILD SOMETHING LEGENDARY")
                .font(Theme.Font.eyebrow(11))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text("Schedule a private consultation to discuss your real estate or investment goals.")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.inkSoft)
            NavigationLink("Book a Consultation") { ConsultationFormView() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func loadPreviews() async {
        async let properties = try? session.apiClient.fetchListings(type: .property)
        async let investments = try? session.apiClient.fetchListings(type: .investment)
        let (propertiesResult, investmentsResult) = await (properties, investments)

        propertiesState = propertiesResult.map { .loaded(Array($0.prefix(6))) } ?? .failed(APIError.network(underlying: "Failed to load"))
        investmentsState = investmentsResult.map { .loaded(Array($0.prefix(6))) } ?? .failed(APIError.network(underlying: "Failed to load"))
    }
}

#Preview {
    HomeView().environmentObject(SessionStore())
}
