import Combine
import CoreData
import Foundation

class GroceryListViewModel: ObservableObject {

    // Cycle: needed → bought → needed
    func toggleState(for item: GroceryItem, context: NSManagedObjectContext) {
        switch item.groceryState {
        case .needed: item.state = GroceryState.bought.rawValue
        case .bought: item.state = GroceryState.needed.rawValue
        }
        try? context.save()
    }

    // Remove all bought items
    func clearChecked(context: NSManagedObjectContext) {
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(format: "state == %@", GroceryState.bought.rawValue)
        if let items = try? context.fetch(request) {
            items.forEach { context.delete($0) }
        }
        try? context.save()
    }

    /// Groups needed items by aisle. Known aisles appear in AisleCategory.allCases order,
    /// items with no aisle set appear last under a nil group.
    func groupedNeededItems(from items: [GroceryItem]) -> [(aisle: AisleCategory?, items: [GroceryItem])] {
        let needed = items.filter { $0.groceryState == .needed }
        let grouped = Dictionary(grouping: needed) { $0.aisle }

        // Known aisles in canonical order
        var result: [(aisle: AisleCategory?, items: [GroceryItem])] = AisleCategory.allCases
            .compactMap { cat in
                guard let aisleItems = grouped[cat], !aisleItems.isEmpty else { return nil }
                return (aisle: cat, items: aisleItems.sorted {
                    ($0.addedAt ?? .distantPast) < ($1.addedAt ?? .distantPast)
                })
            }

        // Items with no aisle set — appended last
        if let ungrouped = grouped[nil], !ungrouped.isEmpty {
            result.append((aisle: nil, items: ungrouped.sorted {
                ($0.addedAt ?? .distantPast) < ($1.addedAt ?? .distantPast)
            }))
        }
        return result
    }
}
