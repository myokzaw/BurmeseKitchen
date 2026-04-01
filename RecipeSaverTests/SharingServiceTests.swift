import XCTest
@testable import RecipeSaver

final class SharingServiceTests: XCTestCase {
    func test_encode_producesValidURL() {
        let context = TestCoreDataStack.makeContext()
        let recipe = TestCoreDataStack.makeRecipe(title: "Mohinga", in: context)

        let url = SharingService.encode(recipe: recipe)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "recipesaver")
    }

    func test_decode_roundTrip() {
        let context = TestCoreDataStack.makeContext()
        let recipe = TestCoreDataStack.makeRecipe(title: "Shan Noodles", in: context)
        recipe.desc = "Delicious noodles"
        recipe.category = MealCategory.noodles.rawValue

        guard let url = SharingService.encode(recipe: recipe) else {
            return XCTFail("encode returned nil")
        }

        let decoded = SharingService.decode(url: url)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.title, "Shan Noodles")
        XCTAssertEqual(decoded?.desc, "Delicious noodles")
        XCTAssertEqual(decoded?.category, MealCategory.noodles.rawValue)
    }

    func test_decode_invalidURL_returnsNil() {
        let bad = URL(string: "recipesaver://share?data=NOTBASE64%%%%")!
        XCTAssertNil(SharingService.decode(url: bad))
    }
}
