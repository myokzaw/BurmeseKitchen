import XCTest
@testable import RecipeSaver

final class ScalingServiceTests: XCTestCase {
    func test_scale_doubleServings() {
        let result = ScalingService.scale(quantity: 2.0, from: 2, to: 4)
        XCTAssertEqual(result, 4.0)
    }

    func test_scale_halfServings() {
        let result = ScalingService.scale(quantity: 3.0, from: 3, to: 1)
        XCTAssertEqual(result, 1.0)
    }

    func test_scale_snapsToNiceFraction() {
        let result = ScalingService.scale(quantity: 1.0, from: 3, to: 4)
        XCTAssertEqual(result, 1.33, accuracy: 0.01)
    }

    func test_scale_sameServings_returnsOriginal() {
        let result = ScalingService.scale(quantity: 2.5, from: 4, to: 4)
        XCTAssertEqual(result, 2.5)
    }

    func test_scale_neverReturnsNegative() {
        let result = ScalingService.scale(quantity: 1.0, from: 4, to: 0)
        XCTAssertGreaterThanOrEqual(result, 0)
    }
}
