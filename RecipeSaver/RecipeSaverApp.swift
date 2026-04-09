import SwiftUI
import CoreData

@main
struct RecipeSaverApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              persistence.container.viewContext)
                .environmentObject(settings)
                .onOpenURL { url in
                    NotificationCenter.default.post(
                        name: .didReceiveSharedRecipe,
                        object: SharingService.decode(url: url)
                    )
                }
                .task {
                    seedBurmeseRecipesIfNeeded()
                }
        }
    }

    // MARK: - v2 Seeding
    // Uses a versioned UserDefaults key so the starter recipe library can be
    // expanded and reseeded for existing installs when built-in content changes.

    private func seedBurmeseRecipesIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "hasSeededRecipesV4") else { return }

        let context = persistence.container.viewContext

        // Remove old built-in recipes so v2 Burmese recipes replace them
        let deleteRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        deleteRequest.predicate = NSPredicate(format: "isBuiltIn == YES")
        if let oldRecipes = try? context.fetch(deleteRequest) {
            for old in oldRecipes { context.delete(old) }
        }

        // Load and decode the v2 JSON
        guard let url = Bundle.main.url(forResource: "StarterRecipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payloads = try? JSONDecoder().decode([V2StarterRecipe].self, from: data)
        else { return }

        for payload in payloads {
            let recipe = Recipe(context: context)
            recipe.id          = UUID()
            recipe.title       = payload.title
            recipe.titleMy     = payload.titleMy
            recipe.desc        = payload.desc
            recipe.descMy      = payload.descMy
            recipe.category    = payload.category
            recipe.region      = payload.region
            recipe.difficulty  = payload.difficulty
            recipe.prepMinutes = Int16(payload.prepMinutes)
            recipe.cookMinutes = Int16(payload.cookMinutes)
            recipe.baseServings = Int16(payload.baseServings)
            recipe.culturalNote = payload.culturalNote
            if let coverImageName = payload.coverImageName, !coverImageName.isEmpty {
                recipe.coverImageName = coverImageName
                recipe.coverImagePath = nil
                recipe.isCustomCoverImage = false
            } else {
                recipe.coverImageName = nil
                recipe.coverImagePath = nil
                recipe.isCustomCoverImage = false
            }
            recipe.isBuiltIn   = true
            recipe.createdAt   = Date()

            for ing in payload.ingredients {
                let ingredient = Ingredient(context: context)
                ingredient.id        = UUID()
                ingredient.name      = ing.name
                ingredient.nameMy    = ing.nameMy
                ingredient.quantity  = ing.quantity
                ingredient.unit      = ing.unit
                ingredient.sortOrder = Int16(ing.sortOrder)
                ingredient.recipe    = recipe

                for sub in ing.substitutions {
                    let substitution = IngredientSubstitution(context: context)
                    substitution.id        = UUID()
                    substitution.note      = sub.note
                    substitution.context   = sub.context
                    substitution.sortOrder = Int16(sub.sortOrder)
                    substitution.ingredient = ingredient
                }
            }

            for step in payload.steps {
                let recipeStep = RecipeStep(context: context)
                recipeStep.id        = UUID()
                recipeStep.body      = step.body
                recipeStep.sortOrder = Int16(step.sortOrder)
                recipeStep.recipe    = recipe
            }
        }

        persistence.save()
        UserDefaults.standard.set(true, forKey: "hasSeededRecipesV4")
    }
}

// MARK: - v2 Starter Recipe Codable Structs

private struct V2StarterRecipe: Codable {
    var title: String
    var titleMy: String
    var desc: String
    var descMy: String
    var category: String
    var region: String
    var difficulty: String
    var prepMinutes: Int
    var cookMinutes: Int
    var baseServings: Int
    var culturalNote: String
    var coverImageName: String?
    var ingredients: [V2Ingredient]
    var steps: [V2Step]
}

private struct V2Ingredient: Codable {
    var name: String
    var nameMy: String
    var quantity: Double
    var unit: String
    var sortOrder: Int
    var substitutions: [V2Substitution]
}

private struct V2Substitution: Codable {
    var note: String
    var context: String
    var sortOrder: Int
}

private struct V2Step: Codable {
    var body: String
    var sortOrder: Int
}

// MARK: - Notification Names

extension Notification.Name {
    static let didReceiveSharedRecipe = Notification.Name("didReceiveSharedRecipe")
    static let recipeFeedbackEvent    = Notification.Name("recipeFeedbackEvent")
    static let navigateToRecipe       = Notification.Name("navigateToRecipe")
}

enum RecipeFeedbackAction: String {
    case copied
    case deleted
    case copyViewed   // fired when user taps "View" on the copy banner
}
