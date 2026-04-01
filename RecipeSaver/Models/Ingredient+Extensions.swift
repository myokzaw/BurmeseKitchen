import CoreData

extension Ingredient {

    var sortedSubstitutions: [IngredientSubstitution] {
        (substitutions as? Set<IngredientSubstitution> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var hasSubstitutions: Bool {
        !sortedSubstitutions.isEmpty
    }

    var nameMyanmar: String? {
        guard let n = nameMy, !n.isEmpty else { return nil }
        return n
    }
}
