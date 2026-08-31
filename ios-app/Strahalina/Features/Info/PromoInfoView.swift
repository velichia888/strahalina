import SwiftUI

/// One reusable screen for the mockup's three parallel "For Buyers /
/// For Sellers / For Investors" promo pages — same layout, different
/// copy and destination. This is legitimate static marketing copy
/// about real services (not fabricated data), so it's fine to hardcode
/// directly; only the CTA needs to route somewhere real.
struct PromoInfoView: View {
    let icon: String
    let title: String
    let pitch: String
    let bullets: [String]
    let ctaTitle: String
    let destination: PromoDestination

    @State private var navigate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.accent)
                    Text(title)
                        .font(Theme.Font.headline(22))
                        .foregroundStyle(Theme.ink)
                    Text(pitch)
                        .font(Theme.Font.body(15))
                        .foregroundStyle(Theme.inkSoft)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.accent)
                            Text(bullet)
                                .font(Theme.Font.body(14))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))

                Button(ctaTitle) { navigate = true }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(destinationLink)
    }

    @ViewBuilder
    private var destinationLink: some View {
        NavigationLink(isActive: $navigate) {
            switch destination {
            case .browseProperties:
                BrowseFeedView(initialTypeFilter: .property)
            case .consultation:
                ConsultationFormView()
            case .investorInquiry:
                InvestorInquiryFormView()
            }
        } label: {
            EmptyView()
        }
    }
}

enum PromoDestination {
    case browseProperties
    case consultation
    case investorInquiry
}

extension PromoInfoView {
    static let forBuyers = PromoInfoView(
        icon: "person.crop.circle.badge.checkmark",
        title: "For Buyers",
        pitch: "We find the right property. You build your future.",
        bullets: [
            "Access to exclusive listings",
            "Expert negotiation",
            "Market insights",
            "Smooth transaction process",
        ],
        ctaTitle: "Browse Properties",
        destination: .browseProperties
    )

    static let forSellers = PromoInfoView(
        icon: "megaphone",
        title: "For Sellers",
        pitch: "We position. We market. We deliver results.",
        bullets: [
            "Strategic pricing",
            "Premium marketing",
            "Global exposure",
            "Proven track record",
        ],
        ctaTitle: "Book a Consultation",
        destination: .consultation
    )

    static let forInvestors = PromoInfoView(
        icon: "chart.line.uptrend.xyaxis",
        title: "For Investors",
        pitch: "Opportunities. Due diligence. Maximum returns.",
        bullets: [
            "Off-market deals",
            "Detailed underwriting",
            "Risk management",
            "Consistent performance",
        ],
        ctaTitle: "Submit Investor Inquiry",
        destination: .investorInquiry
    )
}

#Preview {
    NavigationStack { PromoInfoView.forBuyers }.environmentObject(SessionStore())
}
