import CoreData

extension GroceryItem {
    var groceryState: GroceryState {
        GroceryState(rawValue: state ?? "") ?? .needed
    }

    var ingredientUnit: IngredientUnit {
        IngredientUnit(rawValue: unit ?? "") ?? .none
    }

    // MARK: - v3 aisle
    /// Parsed aisle category. Returns nil if unset (items without an aisle go in a catch-all section).
    var aisle: AisleCategory? {
        guard let raw = aisleCategory else { return nil }
        return AisleCategory(rawValue: raw)
    }
}
