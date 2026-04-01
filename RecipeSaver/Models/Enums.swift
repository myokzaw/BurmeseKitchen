import Foundation

enum MealCategory: String, CaseIterable {
    // v1
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"
    case dessert   = "dessert"
    // v2 — Burmese-specific
    case noodles    = "noodles"
    case curry      = "curry"
    case salad      = "salad"
    case soup       = "soup"
    case ceremonial = "ceremonial"
}

enum Difficulty: String, CaseIterable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"
}

enum IngredientUnit: String, CaseIterable {
    case cup   = "cup"
    case tbsp  = "tbsp"
    case tsp   = "tsp"
    case grams = "g"
    case oz    = "oz"
    case ml    = "ml"
    case piece = "piece"
    case pinch = "pinch"
    case none  = "none"
}

enum GroceryState: String, CaseIterable {
    case needed = "needed"
    case bought = "bought"
}

enum SpiceCategory: String, CaseIterable {
    case driedSpices   = "driedSpices"      // Cumin, coriander, etc.
    case freshHerbs    = "freshHerbs"       // Cilantro, mint, basil, etc.
    case spiceBlends   = "spiceBlends"      // Curry powder, garam masala, etc.
    case heatElements  = "heatElements"     // Chili, cayenne, etc.
    case aromatics     = "aromatics"        // Star anise, cinnamon, etc.
    
    var displayName: String {
        switch self {
        case .driedSpices:  return "Dried Spices"
        case .freshHerbs:   return "Fresh Herbs"
        case .spiceBlends:  return "Spice Blends"
        case .heatElements: return "Heat Elements"
        case .aromatics:    return "Aromatics"
        }
    }
}
