import XCTest
import CoreData
@testable import RecipeSaver

final class GroceryListTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestCoreDataStack.makeContext()
    }

    // MARK: - Toggle tests

    func test_toggle_neededToBought() throws {
        let item = TestCoreDataStack.makeGroceryItem(state: .needed, in: context)
        XCTAssertEqual(item.groceryState, .needed)

        item.state = GroceryState.bought.rawValue
        try context.save()

        XCTAssertEqual(item.groceryState, .bought)
    }

    func test_toggle_boughtToNeeded() throws {
        let item = TestCoreDataStack.makeGroceryItem(state: .bought, in: context)
        XCTAssertEqual(item.groceryState, .bought)

        item.state = GroceryState.needed.rawValue
        try context.save()

        XCTAssertEqual(item.groceryState, .needed)
    }

    func test_toggle_roundTrip() {
        let item = TestCoreDataStack.makeGroceryItem(state: .needed, in: context)

        item.state = GroceryState.bought.rawValue
        XCTAssertEqual(item.groceryState, .bought)

        item.state = GroceryState.needed.rawValue
        XCTAssertEqual(item.groceryState, .needed)

        item.state = GroceryState.bought.rawValue
        XCTAssertEqual(item.groceryState, .bought)
    }

    func test_noHaveAtHomeState() {
        // haveAtHome was removed in v2.1 — legacy values fall back to .needed
        let item = TestCoreDataStack.makeGroceryItem(in: context)
        item.state = "haveAtHome"
        XCTAssertEqual(item.groceryState, .needed, "haveAtHome should fall back to .needed")
    }

    func test_deleteItem_removesFromContext() throws {
        let item = TestCoreDataStack.makeGroceryItem(in: context)
        let id = item.id!
        try context.save()

        context.delete(item)
        try context.save()

        let fetch = NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        XCTAssertTrue(try context.fetch(fetch).isEmpty)
    }

    func test_clearBought_onlyRemovesBought() throws {
        let needed = TestCoreDataStack.makeGroceryItem(name: "Lemongrass", state: .needed, in: context)
        let bought1 = TestCoreDataStack.makeGroceryItem(name: "Fish sauce", state: .bought, in: context)
        let bought2 = TestCoreDataStack.makeGroceryItem(name: "Noodles",    state: .bought, in: context)
        try context.save()

        [bought1, bought2].forEach { context.delete($0) }
        try context.save()

        let fetch = NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
        let remaining = try context.fetch(fetch)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.name, "Lemongrass")
        _ = needed
    }
}
