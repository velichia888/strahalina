import SwiftUI

/// Dark luxury real-estate palette — near-black canvas, warm gold accent,
/// cream/white text — extracted from the user-supplied "The One
/// Enterprises" / Muradyan Group Capital brand mockups (see
/// ~/Desktop/apps/strahalina). Property photography reads best on a dark
/// ground with a single warm accent color, matching those mockups'
/// moody dusk/interior-lit property shots and gold CTA buttons.
enum Theme {
    static let canvas = Color(hex: "#141210")
    static let surface = Color(hex: "#1E1B17")
    static let surfaceRaised = Color(hex: "#262219")
    static let ink = Color(hex: "#F5F1E8")
    static let inkSoft = Color(hex: "#ACA595")
    static let inkFaint = Color(hex: "#726B5C")
    static let accent = Color(hex: "#C9A876")
    static let accentDeep = Color(hex: "#B08D57")
    static let borderSubtle = Color(hex: "#332F27")
    static let danger = Color(hex: "#E5675F")
    static let dangerSoft = Color(hex: "#3A211E")

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#D8BC8C"), Color(hex: "#B08D57")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let primaryShadow = Color(hex: "#000000").opacity(0.4)

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Font {
        static func body(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, design: .default)
        }
        static func headline(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .default)
        }
        /// Small tracked-uppercase label ("PROPERTIES", "FOR BUYERS") —
        /// pair with `.textCase(.uppercase)` and `.tracking(1.5)` at the
        /// call site, matching the mockups' eyebrow-label treatment.
        static func eyebrow(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
    }

    static func statusColor(for status: ListingStatus) -> Color {
        switch status {
        case .active: return Color(hex: "#5FBF7A")
        case .pending: return accent
        case .sold: return inkFaint
        }
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
