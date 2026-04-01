import CoreData

extension Recipe {
    var sortedIngredients: [Ingredient] {
        (ingredients as? Set<Ingredient> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedSteps: [RecipeStep] {
        (steps as? Set<RecipeStep> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedSpices: [Spice] {
        (spices as? Set<Spice> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var spicesByCategory: [SpiceCategory: [Spice]] {
        Dictionary(grouping: sortedSpices) { $0.spiceCategory }
    }

    var mealCategory: MealCategory {
        MealCategory(rawValue: category ?? "") ?? .dinner
    }

    var difficultyLevel: Difficulty {
        Difficulty(rawValue: difficulty ?? "") ?? .easy
    }

    // MARK: - v2 accessors
    var recipeRegion: String {
        let r = region ?? ""
        return r.isEmpty ? "Nationwide" : r
    }

    var titleMyanmar: String? {
        guard let t = titleMy, !t.isEmpty else { return nil }
        return t
    }

    var descMyanmar: String? {
        guard let d = descMy, !d.isEmpty else { return nil }
        return d
    }

    var culturalContext: String? {
        guard let n = culturalNote, !n.isEmpty else { return nil }
        return n
    }

    // MARK: - Image handling
    
    /// Determines whether to use the default asset image or custom cover image
    var shouldUseDefaultImage: Bool {
        // Use default if:
        // 1. It's a built-in recipe AND not customized
        // 2. There's a coverImageName available
        (isBuiltIn || !isCustomCoverImage) && !(coverImageName ?? "").isEmpty
    }

    /// Gets the image name for default asset image
    var defaultImageAssetName: String? {
        guard shouldUseDefaultImage else { return nil }
        return coverImageName
    }

    /// Gets the file path for custom cover image
    var customImagePath: String? {
        guard !shouldUseDefaultImage, let path = coverImagePath, !path.isEmpty else { return nil }
        return path
    }
}
