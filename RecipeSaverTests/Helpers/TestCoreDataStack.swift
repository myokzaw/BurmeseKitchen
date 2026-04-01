import CoreData
@testable import RecipeSaver

// In-memory CoreData stack for unit tests — never touches disk.
class TestCoreDataStack {
    static func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "RecipeSaver")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError("Test CoreData failed: \(error)") }
        }
        return container.viewContext
    }

    static func makeGroceryItem(
        name: String = "Catfish",
        quantity: Double = 400,
        unit: String = "g",
        state: GroceryState = .needed,
        in context: NSManagedObjectContext
    ) -> GroceryItem {
        let item = GroceryItem(context: context)
        item.id       = UUID()
        item.name     = name
        item.quantity = quantity
        item.unit     = unit
        item.state    = state.rawValue
        item.addedAt  = Date()
        return item
    }

    static func makeRecipe(
        title: String = "Test Recipe",
        isBuiltIn: Bool = false,
        in context: NSManagedObjectContext
    ) -> Recipe {
        let recipe = Recipe(context: context)
        recipe.id           = UUID()
        recipe.title        = title
        recipe.isBuiltIn    = isBuiltIn
        recipe.baseServings = 2
        recipe.createdAt    = Date()
        return recipe
    }
}
