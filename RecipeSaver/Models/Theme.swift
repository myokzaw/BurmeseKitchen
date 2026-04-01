import SwiftUI

// MARK: - Iris Garden Design System

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct Theme {
    // Primary
    static let primary = Color(hex: "#4f055d")
    static let primaryContainer = Color(hex: "#692475")
    static let primaryFixed = Color(hex: "#ffd6fe")
    static let primaryFixedDim = Color(hex: "#f8acff")

    // Tertiary
    static let tertiary = Color(hex: "#0f3412")
    static let tertiaryFixed = Color(hex: "#c2eebb")
    static let tertiaryFixedDim = Color(hex: "#a7d2a1")

    // Surface
    static let surface = Color(hex: "#fcfcd7")
    static let surfaceContainer = Color(hex: "#f0f0cc")
    static let surfaceContainerLow = Color(hex: "#f6f6d1")
    static let surfaceContainerHigh = Color(hex: "#ebeac6")
    static let surfaceVariant = Color(hex: "#e5e5c1")

    // On colors
    static let onBackground = Color(hex: "#1c1d07")
    static let onSurface = Color(hex: "#1c1d07")
    static let onSurfaceVariant = Color(hex: "#4f434e")
    static let outlineVariant = Color(hex: "#d2c2cf")

    // Secondary
    static let secondary = Color(hex: "#75527d")
    static let secondaryContainer = Color(hex: "#f8cbfe")

    // Shadows
    static let cardShadow = Color(hex: "#1c1d07").opacity(0.05)
    static let appBarShadow = Color(hex: "#1c1d07").opacity(0.06)

    // Typography helpers
    static func serifFont(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "Newsreader-Italic" : "Newsreader-Regular", size: size)
    }

    static func sansFont(_ size: CGFloat, weight: SansFontWeight = .regular) -> Font {
        switch weight {
        case .regular:
            return .custom("Manrope-Regular", size: size)
        case .semiBold:
            return .custom("Manrope-SemiBold", size: size)
        case .bold:
            return .custom("Manrope-Bold", size: size)
        }
    }

    enum SansFontWeight {
        case regular, semiBold, bold
    }
}
