import Foundation

struct ScalingService {
    static func scale(quantity: Double, from base: Int, to target: Int) -> Double {
        guard base > 0 else { return quantity }
        let raw = quantity * Double(target) / Double(base)
        return roundToNiceFraction(raw)
    }

    /// Formats a quantity as a human-readable string using vulgar fraction symbols.
    /// e.g. 1.5 → "1 ½", 0.25 → "¼", 190.5 → "190 ½", 3.0 → "3"
    /// Never produces scientific notation. Handles the exact fractions ScalingService produces.
    static func formatQuantity(_ value: Double) -> String {
        guard value > 0 else { return "0" }
        let whole = Int(floor(value))
        let frac  = value - floor(value)

        if frac < 0.05 { return "\(whole)" }
        if frac > 0.95 { return "\(whole + 1)" }

        let fracStr: String
        switch frac {
        case let f where abs(f - 0.25) < 0.05: fracStr = "¼"
        case let f where abs(f - 0.33) < 0.06: fracStr = "⅓"
        case let f where abs(f - 0.5)  < 0.05: fracStr = "½"
        case let f where abs(f - 0.67) < 0.06: fracStr = "⅔"
        case let f where abs(f - 0.75) < 0.05: fracStr = "¾"
        default:
            // Fallback for unexpected fractions — 1 decimal, never scientific notation
            return String(format: "%.1f", value)
        }

        return whole == 0 ? fracStr : "\(whole) \(fracStr)"
    }

    private static func roundToNiceFraction(_ value: Double) -> Double {
        let fractions = [0.25, 0.33, 0.5, 0.67, 0.75]
        let whole = floor(value)
        let frac = value - whole
        if frac < 0.1 { return whole }
        if frac > 0.9 { return whole + 1 }
        let nearest = fractions.min { abs($0 - frac) < abs($1 - frac) }!
        return whole + nearest
    }
}
