import SwiftUI
import CoreData
import Combine

class RecipeDetailViewModel: ObservableObject {
    let recipe: Recipe
    @Published var currentServings: Int

    init(recipe: Recipe) {
        self.recipe = recipe
        self.currentServings = Int(recipe.baseServings)
    }

    func scaledQuantity(for ingredient: Ingredient) -> Double {
        ScalingService.scale(
            quantity: ingredient.quantity,
            from: Int(recipe.baseServings),
            to: currentServings
        )
    }

    func formattedQuantity(for ingredient: Ingredient) -> String {
        let scaled = scaledQuantity(for: ingredient)
        if scaled == floor(scaled) {
            return String(format: "%.0f", scaled)
        }
        return String(format: "%.2g", scaled)
    }
}
