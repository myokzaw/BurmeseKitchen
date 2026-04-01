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
}
