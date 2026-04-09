import Foundation

/// Offline macro estimator. Pure function — no state, no CoreData, no network.
struct NutritionService {

    // MARK: - Unit-to-gram conversion
    private static let unitToGrams: [String: Double] = [
        "g":      1.0,
        "oz":     28.35,
        "cup":    240.0,
        "tbsp":   15.0,
        "tsp":    5.0,
        "ml":     1.0,
        "piece":  100.0,
        "pinch":  0.5,
        "none":   0.0
    ]

    // MARK: - Nutrient lookup table (~80 common Burmese kitchen ingredients)
    // Key: lowercase keyword to match against ingredient name
    // Value: (caloriesPer100g, proteinG, carbsG, fatG)
    private static let lookup: [String: (cal: Double, pro: Double, carb: Double, fat: Double)] = [
        // Proteins
        "chicken":          (165, 31.0, 0.0,  3.6),
        "beef":             (250, 26.0, 0.0,  17.0),
        "pork":             (242, 27.0, 0.0,  14.0),
        "fish":             (136, 20.0, 0.0,  6.0),
        "catfish":          (105, 18.0, 0.0,  2.9),
        "prawn":            (99,  24.0, 0.9,  0.3),
        "shrimp":           (99,  24.0, 0.9,  0.3),
        "crab":             (87,  18.0, 0.0,  1.1),
        "squid":            (92,  16.0, 3.1,  1.4),
        "mackerel":         (205, 19.0, 0.0,  14.0),
        "sardine":          (208, 25.0, 0.0,  11.0),
        "anchovy":          (131, 20.0, 0.0,  4.8),
        "duck":             (337, 19.0, 0.0,  28.0),
        "lamb":             (294, 25.0, 0.0,  21.0),
        "egg":              (155, 13.0, 1.1,  11.0),
        "tofu":             (76,  8.0,  1.9,  4.8),
        // Carbs & grains
        "rice":             (130, 2.7,  28.0, 0.3),
        "noodle":           (138, 4.5,  25.0, 2.1),
        "flour":            (364, 10.0, 76.0, 1.0),
        "bread":            (265, 9.0,  49.0, 3.2),
        "banana":           (89,  1.1,  23.0, 0.3),
        "potato":           (77,  2.0,  17.0, 0.1),
        "lentil":           (116, 9.0,  20.0, 0.4),
        "chickpea":         (164, 8.9,  27.0, 2.6),
        "bean sprout":      (30,  3.1,  5.9,  0.2),
        // Vegetables
        "onion":            (40,  1.1,  9.3,  0.1),
        "garlic":           (149, 6.4,  33.0, 0.5),
        "ginger":           (80,  1.8,  18.0, 0.8),
        "tomato":           (18,  0.9,  3.9,  0.2),
        "lemongrass":       (99,  1.8,  25.0, 0.5),
        "chilli":           (40,  2.0,  9.0,  0.4),
        "spinach":          (23,  2.9,  3.6,  0.4),
        "cabbage":          (25,  1.3,  6.0,  0.1),
        "mushroom":         (22,  3.1,  3.3,  0.3),
        "carrot":           (41,  0.9,  10.0, 0.2),
        "pea":              (81,  5.4,  14.0, 0.4),
        "eggplant":         (25,  1.0,  6.0,  0.2),
        "spring onion":     (32,  1.8,  7.3,  0.2),
        "shallot":          (72,  2.5,  17.0, 0.1),
        "celery":           (16,  0.7,  3.0,  0.2),
        "cucumber":         (15,  0.6,  3.6,  0.1),
        "bitter melon":     (17,  1.0,  3.7,  0.2),
        "drumstick leaf":   (64,  9.8,  8.3,  1.4),
        // Dairy & fats
        "butter":           (717, 0.9,  0.1,  81.0),
        "oil":              (884, 0.0,  0.0,  100.0),
        "coconut milk":     (230, 2.3,  6.0,  24.0),
        "milk":             (61,  3.2,  4.8,  3.3),
        "cream":            (340, 2.1,  2.8,  36.0),
        "ghee":             (900, 0.0,  0.0,  100.0),
        // Condiments & spices
        "fish sauce":       (35,  5.0,  3.6,  0.0),
        "soy sauce":        (53,  8.1,  4.9,  0.1),
        "oyster sauce":     (51,  0.9,  11.0, 0.3),
        "shrimp paste":     (205, 41.0, 3.8,  4.0),
        "sugar":            (387, 0.0,  100.0,0.0),
        "salt":             (0,   0.0,  0.0,  0.0),
        "turmeric":         (354, 8.0,  65.0, 10.0),
        "cumin":            (375, 18.0, 44.0, 22.0),
        "coriander":        (298, 12.0, 55.0, 18.0),
        "tamarind":         (239, 2.8,  63.0, 0.6),
        "cardamom":         (311, 11.0, 68.0, 7.0),
        "star anise":       (337, 18.0, 50.0, 16.0),
        "bay leaf":         (313, 8.0,  75.0, 8.0),
        "cinnamon":         (247, 4.0,  81.0, 1.2),
        "paprika":          (282, 14.0, 54.0, 13.0),
        "sesame":           (573, 17.0, 23.0, 50.0),
        "peanut":           (567, 26.0, 16.0, 49.0),
        "dried chilli":     (282, 12.0, 50.0, 7.0),
        "galangal":         (70,  1.5,  15.0, 0.8),
        "kaffir lime":      (30,  1.5,  7.0,  0.2),
        "belacan":          (205, 41.0, 3.8,  4.0),
        "coconut cream":    (330, 3.4,  6.7,  34.0),
        "vinegar":          (21,  0.0,  0.6,  0.0),
        "honey":            (304, 0.3,  82.0, 0.0),
        // Beverages & stock
        "stock":            (8,   0.5,  1.0,  0.2),
        "broth":            (8,   0.5,  1.0,  0.2),
        "water":            (0,   0.0,  0.0,  0.0),
        "tea":              (1,   0.0,  0.3,  0.0)
    ]

    // MARK: - Public API

    /// Estimates macros per serving for a recipe at the given serving count.
    /// Returns nil if fewer than 50% of ingredients matched the lookup table.
    static func estimate(for recipe: Recipe, servings: Int) -> NutrientSummary? {
        var totalCal:  Double = 0
        var totalPro:  Double = 0
        var totalCarb: Double = 0
        var totalFat:  Double = 0
        var matched = 0
        var total = 0

        let allItems: [(name: String, quantity: Double, unit: String)] =
            recipe.sortedIngredients.map { ($0.name ?? "", $0.quantity, $0.unit ?? "") } +
            recipe.sortedSpices.map     { ($0.name ?? "", $0.quantity, $0.unit ?? "") }

        for item in allItems {
            total += 1
            let scaledQty = ScalingService.scale(
                quantity: item.quantity,
                from: Int(recipe.baseServings),
                to: servings
            )
            let grams = scaledQty * (unitToGrams[item.unit] ?? 0)
            guard grams > 0 else { continue }

            let nameLower = item.name.lowercased()
            guard let entry = lookup.first(where: { nameLower.contains($0.key) })?.value else { continue }

            let factor = grams / 100.0
            totalCal  += entry.cal  * factor
            totalPro  += entry.pro  * factor
            totalCarb += entry.carb * factor
            totalFat  += entry.fat  * factor
            matched += 1
        }

        let perServing = Double(max(servings, 1))
        let summary = NutrientSummary(
            calories: totalCal  / perServing,
            proteinG: totalPro  / perServing,
            carbsG:   totalCarb / perServing,
            fatG:     totalFat  / perServing,
            matchedCount: matched,
            totalCount:   total
        )
        return summary.isReliable ? summary : nil
    }
}
