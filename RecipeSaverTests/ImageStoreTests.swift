import XCTest
import UIKit
@testable import RecipeSaver

final class ImageStoreTests: XCTestCase {
    func test_save_returnsRelativePath() {
        let id = UUID()
        let image = makeImage(color: .red)

        let path = ImageStore.save(image: image, id: id)

        XCTAssertEqual(path, "covers/\(id.uuidString).jpg")
        ImageStore.delete(path: path)
    }

    func test_load_handlesRelativePath() {
        let id = UUID()
        let image = makeImage(color: .blue)
        let path = ImageStore.save(image: image, id: id)

        let loaded = ImageStore.load(path: path)

        XCTAssertNotNil(loaded)
        ImageStore.delete(path: path)
    }

    func test_delete_removesSavedFile() {
        let id = UUID()
        let image = makeImage(color: .green)
        let path = ImageStore.save(image: image, id: id)
        XCTAssertNotNil(ImageStore.load(path: path))

        ImageStore.delete(path: path)

        XCTAssertNil(ImageStore.load(path: path))
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
