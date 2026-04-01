import UIKit

struct ImageStore {
    private static var coversURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let covers = docs.appendingPathComponent("covers", isDirectory: true)
        try? FileManager.default.createDirectory(at: covers, withIntermediateDirectories: true)
        return covers
    }

    // Returns a RELATIVE path like "covers/UUID.jpg" — stable across iOS app updates
    // (absolute paths break when iOS changes the app container UUID on update)
    static func save(image: UIImage, id: UUID) -> String? {
        let filename = "\(id.uuidString).jpg"
        let url = coversURL.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url, options: .atomic)
        return "covers/\(filename)"
    }

    // Resolves relative path against current Documents directory at load time.
    // Also handles legacy absolute paths stored by v1/v2 builds.
    static func load(path: String?) -> UIImage? {
        guard let path else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if path.hasPrefix("asset:") {
            let assetName = String(path.dropFirst("asset:".count))
            return UIImage(named: assetName)
        } else if path.hasPrefix("/") {
            // Legacy absolute path — try direct load first
            if let img = UIImage(contentsOfFile: path) { return img }
            // Fallback: resolve filename from current Documents (handles container UUID change)
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let resolved = docs.appendingPathComponent("covers/\(filename)")
            return UIImage(contentsOfFile: resolved.path)
        } else {
            // v2.1+ relative path — resolve against current Documents
            let resolved = docs.appendingPathComponent(path)
            return UIImage(contentsOfFile: resolved.path)
        }
    }

    static func delete(path: String?) {
        guard let path else { return }
        guard !path.hasPrefix("asset:") else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            url = docs.appendingPathComponent(path)
        }
        try? FileManager.default.removeItem(at: url)
    }
}
