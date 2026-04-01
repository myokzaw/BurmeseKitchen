import SwiftUI

// MARK: - Royal Plum Color System (v2)
// All views must use these adaptive tokens — never hardcode hex values in views.

extension Color {

    // MARK: - Plum family (primary brand)
    static let plumDeep    = Color(hex: "#4f055d")  // CTAs, nav active, recipe hero header
    static let plumMid     = Color(hex: "#7a2d8a")  // Hover states, category swatch (soup)
    static let plumLight   = Color(hex: "#c9a8d0")  // Dividers, Myanmar script text (light mode)
    static let plumPale    = Color(hex: "#f2e8f4")  // Grocery "bought" state bg, active tab bg (light)

    // MARK: - Terracotta family (accent — substitutions, converter)
    static let terra       = Color(hex: "#c8794a")  // Substitution panels, Converter CTA, region badges
    static let terraMid    = Color(hex: "#e8956a")  // Terra hover state, highlight rings
    static let terraPale   = Color(hex: "#fdf0e8")  // Substitution panel background (light mode)

    // MARK: - Ivory family (surfaces)
    static let ivory       = Color(hex: "#fdf8f0")  // Page background (light mode)
    static let ivoryDim    = Color(hex: "#f0e8dc")  // Card fills, input backgrounds, inactive chips
    static let ivoryDeep   = Color(hex: "#e0d4c4")  // Pressed states, strong dividers

    // MARK: - Foliage family
    static let foliage     = Color(hex: "#0f6e56")  // Ingredient quantities, "have at home" state
    static let foliagePale = Color(hex: "#d4ede6")  // "Have at home" grocery bg (light mode)

    // MARK: - Ink (text, light mode)
    static let ink         = Color(hex: "#1e0d22")  // Primary text — never pure black
    static let inkMid      = Color(hex: "#4a2d52")  // Secondary text, descriptions
    static let inkMuted    = Color(hex: "#7a6080")  // Tertiary text, labels, timestamps

    // MARK: - Dark mode surfaces
    static let darkBase      = Color(hex: "#0e0612")  // Page background (dark mode)
    static let darkSurface   = Color(hex: "#1a0d1e")  // Card fills (dark mode)
    static let darkElevated  = Color(hex: "#261630")  // Input backgrounds, chips (dark mode)
    static let darkBorder    = Color(hex: "#3d2445")  // Dividers, borders (dark mode)

    // MARK: - Dark mode text
    static let darkTextPrimary   = Color(hex: "#f2e8f4")
    static let darkTextSecondary = Color(hex: "#c9a8d0")
    static let darkTextTertiary  = Color(hex: "#7a6080")

    // MARK: - Adaptive helper
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    // MARK: - Adaptive surface tokens (use these in all views)
    static let appBackground  = adaptive(light: .ivory,        dark: .darkBase)
    static let cardFill       = adaptive(light: .ivoryDim,     dark: .darkSurface)
    static let inputFill      = adaptive(light: .ivoryDim,     dark: .darkElevated)
    static let primaryText    = adaptive(light: .ink,          dark: .darkTextPrimary)
    static let secondaryText  = adaptive(light: .inkMid,       dark: .darkTextSecondary)
    static let tertiaryText   = adaptive(light: .inkMuted,     dark: .darkTextTertiary)
    static let accentTint     = adaptive(light: .plumDeep,     dark: .plumLight)
    static let divider        = adaptive(light: .plumLight.opacity(0.35), dark: .darkBorder)
    static let scrimBg        = adaptive(light: .ivoryDim,     dark: .darkSurface)
    static let boughtFill     = adaptive(light: Color(hex: "#f2e8f4"), dark: Color(hex: "#261630"))
}
