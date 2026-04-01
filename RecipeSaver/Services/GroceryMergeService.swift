import CoreData

struct GroceryMergeService {
    static func addRecipeToList(recipe: Recipe, servings: Int, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let existing = (try? context.fetch(fetchRequest)) ?? []
        let recipeName = recipe.title ?? "Untitled"

        // Add ingredients
        for ingredient in recipe.sortedIngredients {
            let scaledQty = ScalingService.scale(
                quantity: ingredient.quantity,
                from: Int(recipe.baseServings),
                to: servings
            )
            let unit = ingredient.unit ?? ""
            let name = ingredient.name ?? ""

            // Only merge with items from the same recipe (same name + unit + recipe)
            if let match = existing.first(where: {
                $0.name?.lowercased() == name.lowercased()
                    && $0.unit == unit
                    && $0.sourceRecipeId == recipe.id
            }) {
                match.quantity += scaledQty
            } else {
                let item = GroceryItem(context: context)
                item.id = UUID()
                item.name = name
                item.quantity = scaledQty
                item.unit = unit
                item.state = GroceryState.needed.rawValue
                item.sourceRecipeId = recipe.id
                item.sourceRecipeName = recipeName
                item.addedAt = Date()
            }
        }

        // Add spices
        for spice in recipe.sortedSpices {
            let scaledQty = ScalingService.scale(
                quantity: spice.quantity,
                from: Int(recipe.baseServings),
                to: servings
            )
            let unit = spice.unit ?? ""
            let name = spice.name ?? ""
            
            // Prefix spice name with category for clarity in grocery list
            let displayName = "🌶️ \(name) (\(spice.spiceCategory.displayName))"

            // Only merge with items from the same recipe (same name + unit + recipe)
            if let match = existing.first(where: {
                $0.name?.lowercased() == displayName.lowercased()
                    && $0.unit == unit
                    && $0.sourceRecipeId == recipe.id
            }) {
                match.quantity += scaledQty
            } else {
                let item = GroceryItem(context: context)
                item.id = UUID()
                item.name = displayName
                item.quantity = scaledQty
                item.unit = unit
                item.state = GroceryState.needed.rawValue
                item.sourceRecipeId = recipe.id
                item.sourceRecipeName = recipeName
                item.addedAt = Date()
            }
        }

        try? context.save()
    }
}

