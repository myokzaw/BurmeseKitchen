import SwiftUI

// MARK: - Royal Plum Type Scale (v2)
// Newsreader (serif) for editorial/display moments.
// Manrope (sans-serif) for functional UI text.
// Myanmar script ALWAYS uses .system() — never these custom fonts.
//
// relativeTo: parameter prevents SwiftUI from attempting font-descriptor
// weight updates on non-variable custom fonts (eliminates console warnings).

extension Font {

    // MARK: - Serif — editorial moments
    static let displayLg  = Font.custom("Newsreader-Italic",   size: 36, relativeTo: .largeTitle)  // Hero recipe title on full-bleed
    static let displayMd  = Font.custom("Newsreader-Italic",   size: 28, relativeTo: .title)        // Screen titles
    static let headlineLg = Font.custom("Newsreader-SemiBold", size: 22, relativeTo: .title2)       // Section headers
    static let headlineMd = Font.custom("Newsreader-Italic",   size: 18, relativeTo: .title3)       // Card titles in list
    static let serif      = Font.custom("Newsreader-Regular",  size: 16, relativeTo: .body)         // Cultural notes, body serif

    // MARK: - Sans — functional text
    static let labelXs    = Font.custom("Manrope-Bold",        size: 9,  relativeTo: .caption2)     // UPPERCASE tracking labels
    static let labelSm    = Font.custom("Manrope-SemiBold",    size: 11, relativeTo: .caption)      // Metadata, badges
    static let body       = Font.custom("Manrope-Regular",     size: 14, relativeTo: .body)         // Body text
    static let bodySm     = Font.custom("Manrope-Regular",     size: 12, relativeTo: .footnote)     // Descriptions
    static let bodyBold   = Font.custom("Manrope-SemiBold",    size: 14, relativeTo: .callout)      // Emphasized body
    static let uiMd       = Font.custom("Manrope-SemiBold",    size: 13, relativeTo: .callout)      // Button labels
    static let uiSm       = Font.custom("Manrope-Medium",      size: 11, relativeTo: .caption)      // Small UI
}
