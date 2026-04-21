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

// MARK: - v3

enum AisleCategory: String, CaseIterable {
    case produce      = "produce"
    case dairy        = "dairy"
    case meat         = "meat"
    case seafood      = "seafood"
    case bakery       = "bakery"
    case frozenFoods  = "frozenFoods"
    case pantry       = "pantry"
    case beverages    = "beverages"
    case household    = "household"
    case other        = "other"

    var displayName: String {
        switch self {
        case .produce:     return "Produce"
        case .dairy:       return "Dairy & Eggs"
        case .meat:        return "Meat & Poultry"
        case .seafood:     return "Seafood"
        case .bakery:      return "Bakery"
        case .frozenFoods: return "Frozen Foods"
        case .pantry:      return "Pantry & Dry Goods"
        case .beverages:   return "Beverages"
        case .household:   return "Household"
        case .other:       return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .produce:     return "leaf"
        case .dairy:       return "drop"
        case .meat:        return "fork.knife"
        case .seafood:     return "fish"
        case .bakery:      return "birthday.cake"
        case .frozenFoods: return "snowflake"
        case .pantry:      return "cabinet"
        case .beverages:   return "cup.and.saucer"
        case .household:   return "house"
        case .other:       return "bag"
        }
    }
}

// MARK: - v4

enum MealSlot: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"

    var displayName: String { rawValue.capitalized }

    var myanmarName: String {
        switch self {
        case .breakfast: return "မနက်စာ"
        case .lunch:     return "နေ့လည်စာ"
        case .dinner:    return "ညစာ"
        case .snack:     return "သရေစာ"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch:     return "sun.max"
        case .dinner:    return "moon.stars"
        case .snack:     return "leaf"
        }
    }
}

enum GroceryGenMode {
    case merge, replace
}

enum ReplaceScope {
    case recipeItemsOnly  // deletes GroceryItems where sourceRecipeId != nil
    case everything       // NSBatchDeleteRequest full wipe
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
