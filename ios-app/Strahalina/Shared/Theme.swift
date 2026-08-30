import SwiftUI

/// Elegant, understated real-estate palette — deep navy ink on a warm
/// cream canvas with a muted gold accent. No real branding/photography
/// yet (placeholder pass, per the established pattern for a first build
/// of any of these apps) — the user supplies real branding later.
enum Theme {
    static let canvas = Color(hex: "#FAF7F0")
    static let surface = Color.white
    static let ink = Color(hex: "#1B2430")
    static let inkSoft = Color(hex: "#4B5563")
    static let inkFaint = Color(hex: "#9CA3AF")
    static let accent = Color(hex: "#B08D57")
    static let borderSubtle = Color(hex: "#E5E0D5")
    static let danger = Color(hex: "#B3261E")
    static let dangerSoft = Color(hex: "#FBEAE9")

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#C9A96A"), Color(hex: "#B08D57")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let primaryShadow = Color(hex: "#B08D57").opacity(0.35)

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
            .system(size: size, weight: .bold, design: .serif)
        }
    }

    static func statusColor(for status: ListingStatus) -> Color {
        switch status {
        case .active: return Color(hex: "#2E7D32")
        case .pending: return Color(hex: "#B08D57")
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
