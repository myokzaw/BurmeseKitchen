import SwiftUI

// Loads a recipe cover image off the main thread to prevent scroll jank.
// Can load from either asset catalog (for default starter recipe images) or file system (for custom images).
// Used by RecipeHeroView, RecipeListCard, RecipeGridCard, and CreateEditRecipeView.
struct AsyncRecipeImage: View {
    let path: String?
    let assetName: String?
    let aspectRatio: CGFloat
    let placeholder: Color

    @State private var image: UIImage? = nil

    init(path: String? = nil, assetName: String? = nil, aspectRatio: CGFloat, placeholder: Color) {
        self.path = path
        self.assetName = assetName
        self.aspectRatio = aspectRatio
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fill)
            } else {
                Rectangle()
                    .fill(placeholder)
                    .aspectRatio(aspectRatio, contentMode: .fit)
            }
        }
        .task(id: assetName ?? path) {
            // Load off main thread — never blocks scrolling or view updates
            image = await Task.detached(priority: .userInitiated) {
                // Prefer asset image if available (default starter recipes)
                if let assetName {
                    return UIImage(named: assetName)
                }
                // Fall back to file path (custom user images)
                return ImageStore.load(path: path)
            }.value
        }
    }
}
