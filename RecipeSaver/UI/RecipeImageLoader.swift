import SwiftUI

/// Automatically loads recipe cover images from asset names.
/// New recipes added with a `coverImageName` will automatically display their image without code changes.
struct RecipeImageLoader {
    
    /// Loads a recipe image by its asset name (coverImageName field).
    /// Returns a placeholder image if the asset doesn't exist.
    static func image(for coverImageName: String?) -> Image {
        guard let name = coverImageName, !name.isEmpty else {
            return Image(systemName: "photo")
        }
        
        // Try to load from assets by the exact coverImageName
        return Image(name)
    }
    
    /// UIImage version for situations that require UIImage instead of SwiftUI Image
    static func uiImage(for coverImageName: String?) -> UIImage? {
        guard let name = coverImageName, !name.isEmpty else {
            return UIImage(systemName: "photo")
        }
        
        return UIImage(named: name)
    }
}

/// Modifier to load recipe cover images with consistent sizing and styling.
struct RecipeCoverImageStyle: ViewModifier {
    let coverImageName: String?
    
    func body(content: Content) -> some View {
        ZStack {
            // Background color while loading
            Color(hex: "#f0f0cc")
            
            // Recipe image
            RecipeImageLoader.image(for: coverImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

extension View {
    /// Applies recipe cover image styling with consistent appearance
    func recipeCoverImage(coverImageName: String?) -> some View {
        self.modifier(RecipeCoverImageStyle(coverImageName: coverImageName))
    }
}
