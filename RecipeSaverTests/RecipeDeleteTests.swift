import XCTest
import CoreData
@testable import RecipeSaver

final class RecipeDeleteTests: XCTestCase {
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestCoreDataStack.makeContext()
    }

    func test_deleteUserRecipe_removesFromContext() throws {
        let recipe = TestCoreDataStack.makeRecipe(title: "My Curry", isBuiltIn: false, in: context)
        let id = try XCTUnwrap(recipe.id)
        try context.save()

        context.delete(recipe)
        try context.save()

        let fetch = NSFetchRequest<Recipe>(entityName: "Recipe")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        XCTAssertTrue(try context.fetch(fetch).isEmpty)
    }

    func test_deleteRecipe_cascadesToIngredients() throws {
        let recipe = TestCoreDataStack.makeRecipe(in: context)

        let ingredient = Ingredient(context: context)
        ingredient.id = UUID()
        ingredient.name = "Catfish"
        ingredient.quantity = 400
        ingredient.unit = "g"
        ingredient.sortOrder = 0
        ingredient.recipe = recipe
        try context.save()

        context.delete(recipe)
        try context.save()

        let fetch = NSFetchRequest<Ingredient>(entityName: "Ingredient")
        XCTAssertTrue(try context.fetch(fetch).isEmpty)
    }

    func test_deleteRecipe_cascadesToSteps() throws {
        let recipe = TestCoreDataStack.makeRecipe(in: context)

        let step = RecipeStep(context: context)
        step.id = UUID()
        step.body = "Simmer for 20 minutes"
        step.sortOrder = 0
        step.recipe = recipe
        try context.save()

        context.delete(recipe)
        try context.save()

        let fetch = NSFetchRequest<RecipeStep>(entityName: "RecipeStep")
        XCTAssertTrue(try context.fetch(fetch).isEmpty)
    }

    func test_builtInRecipe_markedCorrectly() throws {
        let builtIn = TestCoreDataStack.makeRecipe(title: "Mohinga", isBuiltIn: true, in: context)
        let userMade = TestCoreDataStack.makeRecipe(title: "My Curry", isBuiltIn: false, in: context)
        try context.save()

        XCTAssertTrue(builtIn.isBuiltIn)
        XCTAssertFalse(userMade.isBuiltIn)
    }
}
