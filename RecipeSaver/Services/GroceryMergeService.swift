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
                item.aisleCategory = inferAisle(from: name).rawValue
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
                item.aisleCategory = inferAisle(from: name).rawValue
            }
        }

        try? context.save()
    }

    // MARK: - Aisle inference (v3)
    static func inferAisle(from name: String) -> AisleCategory {
        let lower = name.lowercased()
        if lower.contains(anyOf: ["tomato","onion","garlic","ginger","spinach",
                                   "cabbage","mushroom","lemongrass","chilli",
                                   "pepper","carrot","potato","pea","bean sprout",
                                   "spring onion","shallot","coriander leaf","mint"]) { return .produce }
        if lower.contains(anyOf: ["chicken","beef","pork","lamb","duck","turkey",
                                   "mince","sausage"]) { return .meat }
        if lower.contains(anyOf: ["fish","prawn","shrimp","catfish","crab",
                                   "squid","mackerel","sardine","anchovy"]) { return .seafood }
        if lower.contains(anyOf: ["milk","butter","cream","cheese","yogurt","egg"]) { return .dairy }
        if lower.contains(anyOf: ["rice","flour","noodle","oil","sugar","salt",
                                   "soy sauce","fish sauce","tamarind","coconut milk",
                                   "paste","powder","spice","turmeric","cumin",
                                   "coriander","cardamom","star anise","bay leaf",
                                   "sesame","dried","lentil","chickpea","bean"]) { return .pantry }
        if lower.contains(anyOf: ["water","stock","broth","tea","juice"]) { return .beverages }
        if lower.contains(anyOf: ["bread","dough","yeast","bun"]) { return .bakery }
        if lower.contains(anyOf: ["frozen","ice"]) { return .frozenFoods }
        return .other
    }
}

private extension String {
    func contains(anyOf keywords: [String]) -> Bool {
        keywords.contains { self.contains($0) }
    }
}

