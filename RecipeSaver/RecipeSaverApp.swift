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
                    applyStarterContentUpdatesIfNeeded()
                }
        }
    }

    // MARK: - v2 Seeding
    // Uses a versioned UserDefaults key so the starter recipe library can be
    // expanded and reseeded for existing installs when built-in content changes.

    private func seedBurmeseRecipesIfNeeded() {
        let defaults = UserDefaults.standard
        let seedFlagKey = "hasSeededRecipesV4"
        let seedHashKey = "starterRecipesHashV4"

        guard let url = Bundle.main.url(forResource: "StarterRecipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payloads = try? JSONDecoder().decode([V2StarterRecipe].self, from: data)
        else { return }

        let currentHash = starterRecipesHash(for: data)

    #if DEBUG
        let hasSeeded = defaults.bool(forKey: seedFlagKey)
        let previousHash = defaults.string(forKey: seedHashKey)
        guard !hasSeeded || previousHash != currentHash else { return }
    #else
        guard !defaults.bool(forKey: seedFlagKey) else { return }
    #endif

        let context = persistence.container.viewContext

        // Remove old built-in recipes so v2 Burmese recipes replace them
        let deleteRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        deleteRequest.predicate = NSPredicate(format: "isBuiltIn == YES")
        if let oldRecipes = try? context.fetch(deleteRequest) {
            for old in oldRecipes { context.delete(old) }
        }

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
        defaults.set(true, forKey: seedFlagKey)
        defaults.set(currentHash, forKey: seedHashKey)
    }

    // MARK: - Versioned incremental content updates

    private func applyStarterContentUpdatesIfNeeded() {
        let defaults = UserDefaults.standard
        let versionKey = "starterContentVersionV1"

        guard let url = Bundle.main.url(forResource: "StarterContentUpdates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(StarterContentManifest.self, from: data)
        else { return }

        let installedVersion = defaults.integer(forKey: versionKey)
        guard installedVersion < manifest.targetVersion else { return }

        let context = persistence.container.viewContext
        let sortedUpdates = manifest.updates.sorted { $0.version < $1.version }

        for update in sortedUpdates where update.version > installedVersion && update.version <= manifest.targetVersion {
            apply(update: update, in: context)
            defaults.set(update.version, forKey: versionKey)
        }

        persistence.save()
        defaults.set(manifest.targetVersion, forKey: versionKey)
    }

    private func apply(update: StarterContentUpdate, in context: NSManagedObjectContext) {
        var builtInByKey = builtInRecipeMap(in: context)

        for deleteKey in update.deleteRecipeKeys {
            let key = normalizedRecipeKey(deleteKey)
            guard let recipe = builtInByKey[key] else { continue }
            context.delete(recipe)
            builtInByKey.removeValue(forKey: key)
        }

        for payload in update.upsertRecipes {
            let key = builtInRecipeKey(for: payload)
            let recipe = builtInByKey[key] ?? Recipe(context: context)
            let isNewRecipe = builtInByKey[key] == nil

            hydrateBuiltInRecipe(recipe, with: payload, in: context)
            if isNewRecipe {
                builtInByKey[key] = recipe
            }
        }
    }

    private func builtInRecipeMap(in context: NSManagedObjectContext) -> [String: Recipe] {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = NSPredicate(format: "isBuiltIn == YES")
        let recipes = (try? context.fetch(request)) ?? []

        var map: [String: Recipe] = [:]
        for recipe in recipes {
            map[builtInRecipeKey(for: recipe)] = recipe
        }
        return map
    }

    private func builtInRecipeKey(for payload: V2StarterRecipe) -> String {
        if let coverImageName = payload.coverImageName, !coverImageName.isEmpty {
            return normalizedRecipeKey("cover:\(coverImageName)")
        }
        return normalizedRecipeKey("title:\(payload.title)")
    }

    private func builtInRecipeKey(for recipe: Recipe) -> String {
        if let coverImageName = recipe.coverImageName, !coverImageName.isEmpty {
            return normalizedRecipeKey("cover:\(coverImageName)")
        }
        return normalizedRecipeKey("title:\(recipe.title ?? "")")
    }

    private func normalizedRecipeKey(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func hydrateBuiltInRecipe(
        _ recipe: Recipe,
        with payload: V2StarterRecipe,
        in context: NSManagedObjectContext
    ) {
        recipe.id          = recipe.id ?? UUID()
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
        recipe.isBuiltIn   = true
        recipe.createdAt   = recipe.createdAt ?? Date()

        if let coverImageName = payload.coverImageName, !coverImageName.isEmpty {
            recipe.coverImageName = coverImageName
            recipe.coverImagePath = nil
            recipe.isCustomCoverImage = false
        } else {
            recipe.coverImageName = nil
            recipe.coverImagePath = nil
            recipe.isCustomCoverImage = false
        }

        // Built-in updates replace dependent rows to keep ingredient/step order deterministic.
        for ingredient in recipe.sortedIngredients {
            for substitution in ingredient.sortedSubstitutions {
                context.delete(substitution)
            }
            context.delete(ingredient)
        }
        for step in recipe.sortedSteps {
            context.delete(step)
        }

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

    private func starterRecipesHash(for data: Data) -> String {
        // FNV-1a 64-bit gives a stable, fast hash for debug reseeding checks.
        var hash: UInt64 = 14695981039346656037
        let prime: UInt64 = 1099511628211

        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return "\(data.count)-\(String(hash, radix: 16))"
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

private struct StarterContentManifest: Codable {
    var targetVersion: Int
    var updates: [StarterContentUpdate]
}

private struct StarterContentUpdate: Codable {
    var version: Int
    var upsertRecipes: [V2StarterRecipe]
    var deleteRecipeKeys: [String]
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
