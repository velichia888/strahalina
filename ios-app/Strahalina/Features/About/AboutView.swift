import SwiftUI

/// Static content only — no networking. Copy is taken verbatim from the
/// user-supplied "About Us" mockup, not invented: real names,
/// nationalities, and company names as given. No additional biography,
/// achievements, or history beyond what the mockup actually states.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ABOUT US")
                        .font(Theme.Font.eyebrow(11))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text("A partnership built on trust, vision, and execution.")
                        .font(Theme.Font.headline(20))
                        .foregroundStyle(Theme.ink)
                }

                founderCard(
                    name: "Strahil Goodman",
                    flag: "🇧🇬",
                    nationality: "Bulgarian",
                    bio: "Real estate expert, investor, and deal-maker with a passion for creating generational wealth through strategic property acquisition and development."
                )

                founderCard(
                    name: "Alina Muradyan",
                    flag: "🇦🇲🇷🇺",
                    nationality: "Armenian · Russian",
                    bio: "Founder and owner of The One Enterprises and Muradyan Group Capital. Connecting strategic capital with opportunity and building lasting legacies."
                )

                VStack(spacing: Theme.Spacing.sm) {
                    companyRow(name: "The One Enterprises", tagline: "Real Estate · Brokerage · Development")
                    companyRow(name: "Muradyan Group Capital", tagline: "Invest · Grow · Legacy")
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func founderCard(name: String, flag: String, nationality: String, bio: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(Theme.surfaceRaised)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(Theme.inkFaint))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(Theme.Font.body(15).weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(flag) \(nationality)")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Text(bio)
                .font(Theme.Font.body(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func companyRow(name: String, tagline: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Theme.Font.body(14).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(tagline)
                    .font(Theme.Font.body(11))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }
}

#Preview {
    NavigationStack { AboutView() }
}
