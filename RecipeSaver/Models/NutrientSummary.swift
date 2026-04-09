import Foundation

/// Plain Swift struct holding per-serving macro estimates. Never stored in CoreData.
struct NutrientSummary {
    let calories: Double
    let proteinG: Double
    let carbsG:   Double
    let fatG:     Double
    /// Number of ingredients successfully matched in the lookup table.
    let matchedCount: Int
    /// Total number of ingredients in the recipe.
    let totalCount: Int
    /// True if matchedCount / totalCount >= 0.5. If false, caller should not display estimates.
    var isReliable: Bool { totalCount > 0 && Double(matchedCount) / Double(totalCount) >= 0.5 }
}
