import Foundation

struct SharedRecipePayload: Codable {
    var title: String
    var desc: String
    var category: String
    var difficulty: String
    var prepMinutes: Int
    var cookMinutes: Int
    var baseServings: Int
    var ingredients: [SharedIngredient]
    var steps: [SharedStep]
}

struct SharedIngredient: Codable {
    var name: String
    var quantity: Double
    var unit: String
    var sortOrder: Int
}

struct SharedStep: Codable {
    var body: String
    var sortOrder: Int
}

struct SharingService {
    static func encode(recipe: Recipe) -> URL? {
        let payload = SharedRecipePayload(
            title: recipe.title ?? "",
            desc: recipe.desc ?? "",
            category: recipe.category ?? "",
            difficulty: recipe.difficulty ?? "",
            prepMinutes: Int(recipe.prepMinutes),
            cookMinutes: Int(recipe.cookMinutes),
            baseServings: Int(recipe.baseServings),
            ingredients: recipe.sortedIngredients.map {
                SharedIngredient(name: $0.name ?? "", quantity: $0.quantity,
                                 unit: $0.unit ?? "", sortOrder: Int($0.sortOrder))
            },
            steps: recipe.sortedSteps.map {
                SharedStep(body: $0.body ?? "", sortOrder: Int($0.sortOrder))
            }
        )
        guard let data = try? JSONEncoder().encode(payload),
              let base64 = data.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "recipesaver://share?data=\(base64)") else {
            return nil
        }
        return url
    }

    static func decode(url: URL) -> SharedRecipePayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataParam) else {
            return nil
        }
        return try? JSONDecoder().decode(SharedRecipePayload.self, from: data)
    }
}
