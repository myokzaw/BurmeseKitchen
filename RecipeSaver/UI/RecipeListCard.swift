import SwiftUI

// MARK: - Recipe List Card
// Full-bleed 3:2 scrim card for the list view.
// Text is always white — on a dark scrim, not the app surface.
// Myanmar title shown in list view only (not grid).

struct RecipeListCard: View {
    let recipe: Recipe
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Photo layer — loaded async to avoid blocking scroll
            AsyncRecipeImage(
                path: recipe.customImagePath,
                assetName: recipe.defaultImageAssetName,
                aspectRatio: 3 / 2,
                placeholder: RecipeHeroView.placeholderColor(for: recipe.mealCategory)
            )
            .clipped()

            // Scrim
            LinearGradient(
                stops: [
                    .init(color: .clear,                    location: 0.30),
                    .init(color: Color.black.opacity(0.70), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Text — always white on scrim
            VStack(alignment: .leading, spacing: 3) {
                if settings.showBurmese, let titleMy = recipe.titleMyanmar {
                    Text(titleMy)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineSpacing(4)
                }

                Text(recipe.title ?? "")
                    .font(.headlineMd)
                    .foregroundStyle(Color.white)

                HStack(spacing: 8) {
                    Text(recipe.recipeRegion)
                        .font(.labelXs)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.terra.opacity(0.85))
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())

                    Text("\(recipe.prepMinutes + recipe.cookMinutes) min")
                        .font(.labelSm)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Recipe Grid Card (1:1, no Myanmar script)
struct RecipeGridCard: View {
    let recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            AsyncRecipeImage(
                path: recipe.customImagePath,
                assetName: recipe.defaultImageAssetName,
                aspectRatio: 1,
                placeholder: RecipeHeroView.placeholderColor(for: recipe.mealCategory)
            )
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear,                    location: 0.30),
                    .init(color: Color.black.opacity(0.72), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // No Myanmar script in grid — English only
            VStack(alignment: .leading, spacing: 2) {
                Text((recipe.category ?? "").uppercased())
                    .font(.labelXs)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .tracking(1.5)

                Text(recipe.title ?? "")
                    .font(.headlineMd)
                    .foregroundStyle(Color.white)
                    .lineLimit(2)

                Text("\(recipe.prepMinutes + recipe.cookMinutes) min")
                    .font(.uiSm)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
