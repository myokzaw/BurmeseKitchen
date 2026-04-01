import SwiftUI
import CoreData
import Combine

class RecipeListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: MealCategory?
    @Published var isGridView = true

    func predicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", searchText))
        }

        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        if predicates.isEmpty { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
