import CoreData

extension GroceryItem {
    var groceryState: GroceryState {
        GroceryState(rawValue: state ?? "") ?? .needed
    }

    var ingredientUnit: IngredientUnit {
        IngredientUnit(rawValue: unit ?? "") ?? .none
    }
}
