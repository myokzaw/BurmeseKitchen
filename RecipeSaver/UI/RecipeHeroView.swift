import SwiftUI

// MARK: - Recipe Hero View
// Full-bleed 4:3 scrim hero used on RecipeDetailView.
// No corner radius — bleeds to screen edges.
// Text is always white — it sits on the dark scrim, not the app surface.

struct RecipeHeroView: View {
    let recipe: Recipe
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Photo layer — loaded async to avoid blocking the main thread
            AsyncRecipeImage(
                path: recipe.customImagePath,
                assetName: recipe.defaultImageAssetName,
                aspectRatio: 4 / 3,
                placeholder: RecipeHeroView.placeholderColor(for: recipe.mealCategory)
            )
            .clipped()

            // Scrim layer — always dark, independent of color scheme
            LinearGradient(
                stops: [
                    .init(color: .clear,                     location: 0.35),
                    .init(color: Color.black.opacity(0.55),  location: 0.65),
                    .init(color: Color.black.opacity(0.82),  location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Text layer — always white (on dark scrim)
            VStack(alignment: .leading, spacing: 4) {
                Text((recipe.category ?? "").uppercased())
                    .font(.labelXs)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .tracking(1.5)

                Text(recipe.title ?? "")
                    .font(.displayLg)
                    .foregroundStyle(Color.white)

                if settings.showBurmese, let titleMy = recipe.titleMyanmar {
                    Text(titleMy)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineSpacing(4)
                }

                HStack(spacing: 12) {
                    Label("\(recipe.prepMinutes + recipe.cookMinutes) min",
                          systemImage: "clock")
                    Label(recipe.difficulty ?? "",
                          systemImage: "flame")
                }
                .font(.uiSm)
                .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(20)
        }
        // Hero bleeds edge to edge — no corner radius
        .clipShape(Rectangle())
    }

    static func placeholderColor(for category: MealCategory) -> Color {
        switch category {
        case .soup:        return .plumMid
        case .noodles:     return .foliage
        case .curry:       return .terra
        case .salad:       return Color(hex: "#2a5c3f")
        case .dessert:     return Color(hex: "#7a2d8a")
        case .ceremonial:  return Color(hex: "#8B4A0A")
        default:           return .plumDeep
        }
    }
}
