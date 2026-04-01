import Foundation

struct ScalingService {
    static func scale(quantity: Double, from base: Int, to target: Int) -> Double {
        guard base > 0 else { return quantity }
        let raw = quantity * Double(target) / Double(base)
        return roundToNiceFraction(raw)
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
