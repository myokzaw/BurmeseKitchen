import SwiftUI

/// Convenience extension for Recipe to load cover images.
/// Automatically supports any new recipes added to StarterRecipes.json
/// without requiring code changes — just set the `coverImageName` field.
extension Recipe {
    
    /// Returns the recipe's cover image as a SwiftUI Image.
    /// Falls back to a placeholder if the asset doesn't exist.
    var coverImage: Image {
        RecipeImageLoader.image(for: coverImageName)
    }
    
    /// Returns the recipe's cover image as a UIImage.
    /// Useful for situations requiring UIImage (e.g., sharing, image processing).
    func coverUIImage() -> UIImage? {
        RecipeImageLoader.uiImage(for: coverImageName)
    }
}
