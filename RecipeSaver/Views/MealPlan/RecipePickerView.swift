import SwiftUI
import CoreData

struct RecipePickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsStore

    let currentRecipeId: UUID?
    let onSelect: (Recipe) -> Void

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.createdAt, ascending: false)],
        animation: .default
    )
    private var recipes: FetchedResults<Recipe>

    @State private var searchText = ""
    @State private var selectedCategory: MealCategory? = nil

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty ||
                (recipe.title ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                recipe.mealCategory == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.tertiaryText)
                        TextField("Search recipes", text: $searchText)
                            .font(.body)
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(12)
                    .background(Color.inputFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip("All", isActive: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(MealCategory.allCases, id: \.self) { cat in
                                categoryChip(cat.rawValue.capitalized, isActive: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)

                    // Recipe list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredRecipes, id: \.objectID) { recipe in
                                Button {
                                    onSelect(recipe)
                                    dismiss()
                                } label: {
                                    recipeRow(recipe)
                                }
                                .buttonStyle(.plain)

                                if recipe.objectID != filteredRecipes.last?.objectID {
                                    Divider()
                                        .background(Color.divider)
                                        .padding(.leading, 20)
                                }
                            }
                        }
                        .background(Color.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentTint)
                }
            }
        }
    }

    @ViewBuilder
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 14) {
            AsyncRecipeImage(
                assetName: recipe.coverImageName,
                path: recipe.coverImagePath,
                aspect: 1.0,
                focalPoint: recipe.focalPoint
            )
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title ?? "")
                    .font(.bodyBold)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                Text(recipe.mealCategory.rawValue.capitalized)
                    .font(.bodySm)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            if recipe.id == currentRecipeId {
                Image(systemName: "checkmark")
                    .font(.uiMd)
                    .foregroundStyle(Color.accentTint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func categoryChip(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.labelSm)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.accentTint : Color.inputFill)
                .foregroundStyle(isActive ? Color.white : Color.tertiaryText)
                .clipShape(Capsule())
        }
    }
}
