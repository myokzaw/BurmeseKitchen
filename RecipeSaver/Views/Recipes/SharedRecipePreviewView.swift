import SwiftUI
import CoreData

struct SharedRecipePreviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let payload: SharedRecipePayload

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Shared recipe placeholder (no cover photo in share links)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardFill)
                            .frame(height: 160)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title)
                                    Text("Shared Recipe")
                                        .font(.body)
                                }
                                .foregroundStyle(Color.tertiaryText)
                            }

                        // Title
                        Text(payload.title)
                            .font(.displayMd)
                            .foregroundStyle(Color.primaryText)

                        if !payload.desc.isEmpty {
                            Text(payload.desc)
                                .font(.body)
                                .foregroundStyle(Color.secondaryText)
                        }

                        // Metadata
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                sharedMetaPill(icon: "clock",      text: "\(payload.prepMinutes)m prep")
                                sharedMetaPill(icon: "flame",      text: "\(payload.cookMinutes)m cook")
                                sharedMetaPill(icon: "chart.bar",  text: payload.difficulty.capitalized)
                                sharedMetaPill(icon: "tag",        text: payload.category.capitalized)
                            }
                        }

                        // Ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headlineLg)
                                .foregroundStyle(Color.primaryText)

                            ForEach(payload.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.sortOrder) { ing in
                                HStack {
                                    Text(ing.name)
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)
                                    Spacer()
                                    let qtyStr = ing.quantity == floor(ing.quantity)
                                        ? String(format: "%.0f", ing.quantity)
                                        : String(format: "%.2g", ing.quantity)
                                    Text("\(qtyStr) \(ing.unit)")
                                        .font(.bodyBold)
                                        .foregroundStyle(Color.foliage)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        // Steps
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.headlineLg)
                                .foregroundStyle(Color.primaryText)

                            ForEach(payload.steps.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.sortOrder) { step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(step.sortOrder + 1)")
                                        .font(.labelSm)
                                        .foregroundStyle(Color.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.plumDeep)
                                        .clipShape(Circle())

                                    Text(step.body)
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // Save button
                        Button(action: saveToMyRecipes) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save to My Recipes")
                                    .font(.uiMd)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.plumDeep)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.plumDeep.opacity(0.2), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") { dismiss() }
                        .foregroundStyle(Color.accentTint)
                }
            }
        }
    }

    @ViewBuilder
    private func sharedMetaPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.labelSm)
        }
        .foregroundStyle(Color.tertiaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.cardFill)
        .clipShape(Capsule())
    }

    private func saveToMyRecipes() {
        let recipe = Recipe(context: viewContext)
        recipe.id          = UUID()
        recipe.title       = payload.title
        recipe.desc        = payload.desc
        recipe.category    = payload.category
        recipe.difficulty  = payload.difficulty
        recipe.prepMinutes = Int16(payload.prepMinutes)
        recipe.cookMinutes = Int16(payload.cookMinutes)
        recipe.baseServings = Int16(payload.baseServings)
        recipe.isBuiltIn   = false
        recipe.createdAt   = Date()

        for ing in payload.ingredients {
            let ingredient       = Ingredient(context: viewContext)
            ingredient.id        = UUID()
            ingredient.name      = ing.name
            ingredient.quantity  = ing.quantity
            ingredient.unit      = ing.unit
            ingredient.sortOrder = Int16(ing.sortOrder)
            ingredient.recipe    = recipe
        }

        for step in payload.steps {
            let recipeStep       = RecipeStep(context: viewContext)
            recipeStep.id        = UUID()
            recipeStep.body      = step.body
            recipeStep.sortOrder = Int16(step.sortOrder)
            recipeStep.recipe    = recipe
        }

        PersistenceController.shared.save()

        NotificationCenter.default.post(
            name: .recipeFeedbackEvent,
            object: nil,
            userInfo: [
                "action": RecipeFeedbackAction.copied.rawValue,
                "title": recipe.title ?? payload.title
            ]
        )

        dismiss()
    }
}
