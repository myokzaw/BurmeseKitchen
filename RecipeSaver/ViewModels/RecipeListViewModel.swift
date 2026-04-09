import SwiftUI
import Combine
import CoreData

class RecipeListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: MealCategory?
    @Published var isGridView = true
    /// v3: UUID of the recipe hidden during the 3-second undo window. Nil = no pending delete.
    @Published var pendingDeleteID: UUID? = nil

    // MARK: - Predicate (used for CoreData fetch or client-side filter)

    func predicate() -> NSPredicate? {
        var parts: [NSPredicate] = []

        if !searchText.isEmpty {
            parts.append(NSPredicate(format: "title CONTAINS[cd] %@", searchText))
        }

        if let category = selectedCategory {
            parts.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if let deleteID = pendingDeleteID {
            parts.append(NSPredicate(format: "id != %@", deleteID as CVarArg))
        }

        return parts.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: parts)
    }

    // MARK: - Optimistic delete (v3)

    /// Hides the recipe immediately, shows a 3-second undo banner.
    /// onCommit is called when the undo window expires (CoreData write happens here).
    func initiateDelete(recipe: Recipe, onCommit: @escaping () -> Void) {
        let recipeTitle = recipe.title ?? "Recipe"
        pendingDeleteID = recipe.id

        BannerManager.shared.show(FloatingBanner(
            id: UUID(),
            title: "\"\(recipeTitle)\" deleted",
            subtitle: "Tap Undo to restore",
            icon: "trash.fill",
            accentColor: Color.accentTint,
            actionLabel: "Undo",
            duration: 3.0,
            onAction: { [weak self] in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self?.pendingDeleteID = nil
                }
            },
            onDismiss: onCommit
        ))
    }
}
