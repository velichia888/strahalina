import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.body(16).weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundStyle)
            // Dark text on the gold fill, matching the mockups' CTA
            // buttons ("SUBMIT INQUIRY", "SCHEDULE A TOUR") — Theme.ink
            // is a light cream in this dark theme, so it would nearly
            // vanish against gold.
            .foregroundStyle(isDestructive ? .white : Theme.canvas)
            .clipShape(Capsule())
            .shadow(
                color: (isDisabled || isDestructive) ? .clear : Theme.primaryShadow,
                radius: configuration.isPressed ? 4 : 12,
                x: 0,
                y: configuration.isPressed ? 1 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var backgroundStyle: AnyShapeStyle {
        if isDisabled { return AnyShapeStyle(Theme.inkFaint) }
        if isDestructive { return AnyShapeStyle(Theme.danger) }
        return AnyShapeStyle(Theme.primaryGradient)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.body(16).weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.surface)
            .foregroundStyle(Theme.ink)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                    .stroke(Theme.borderSubtle, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A small inline loading indicator paired with label text, used inside
/// buttons while a mutation is in flight.
struct InlineSpinner: View {
    var tint: Color = Theme.ink

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(tint)
            .scaleEffect(0.8)
    }
}
