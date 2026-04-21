import SwiftUI
import CoreData

struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel = RecipeListViewModel()
    @Binding var selectedTab: Int
    @State private var navigatingToRecipe: Recipe? = nil

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.createdAt, ascending: false)],
        animation: .default
    )
    private var recipes: FetchedResults<Recipe>

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = viewModel.searchText.isEmpty ||
                (recipe.title ?? "").localizedCaseInsensitiveContains(viewModel.searchText)
            let matchesCategory = viewModel.selectedCategory == nil ||
                recipe.mealCategory == viewModel.selectedCategory
            // v3: hide recipe during the 3-second undo window
            let notPendingDelete = recipe.id != viewModel.pendingDeleteID
            return matchesSearch && matchesCategory && notPendingDelete
        }
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Screen title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recipes")
                                .font(.displayMd)
                                .foregroundStyle(Color.primaryText)
                            Text("Burmese Kitchen")
                                .font(.labelXs)
                                .foregroundStyle(Color.tertiaryText)
                                .tracking(1.5)
                                .textCase(.uppercase)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.tertiaryText)
                            TextField("Search recipes", text: $viewModel.searchText)
                                .font(.body)
                                .foregroundStyle(Color.primaryText)
                        }
                        .padding(12)
                        .background(Color.inputFill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // Category chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                categoryChip("All", isActive: viewModel.selectedCategory == nil) {
                                    viewModel.selectedCategory = nil
                                }
                                ForEach(MealCategory.allCases, id: \.self) { cat in
                                    categoryChip(cat.rawValue.capitalized, isActive: viewModel.selectedCategory == cat) {
                                        viewModel.selectedCategory = cat
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)

                        // Recipe content
                        if viewModel.isGridView {
                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(filteredRecipes, id: \.objectID) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, selectedTab: $selectedTab, onDeleteRequested: { deleteRecipe(recipe) })) {
                                        RecipeGridCard(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        if !recipe.isBuiltIn {
                                            Button(role: .destructive) {
                                                deleteRecipe(recipe)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredRecipes, id: \.objectID) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, selectedTab: $selectedTab, onDeleteRequested: { deleteRecipe(recipe) })) {
                                        RecipeListCard(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        if !recipe.isBuiltIn {
                                            Button(role: .destructive) {
                                                deleteRecipe(recipe)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { viewModel.isGridView.toggle() }
                    } label: {
                        Image(systemName: viewModel.isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundStyle(Color.accentTint)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateEditRecipeView()) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accentTint)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // v3: navigate to a newly copied recipe from the banner "View" button
            .navigationDestination(item: $navigatingToRecipe) { recipe in
                RecipeDetailView(recipe: recipe, selectedTab: $selectedTab, onDeleteRequested: { deleteRecipe(recipe) })
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToRecipe)) { notification in
                if let recipe = notification.object as? Recipe {
                    navigatingToRecipe = recipe
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func categoryChip(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.labelSm)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.plumDeep : Color.inputFill)
                .foregroundStyle(isActive ? Color.white : Color.tertiaryText)
                .clipShape(Capsule())
        }
    }

    private func deleteRecipe(_ recipe: Recipe) {
        let recipeId = recipe.id
        viewModel.initiateDelete(recipe: recipe) {
            ImageStore.delete(path: recipe.coverImagePath)
            if let id = recipeId {
                MealPlanService.removeAllEntries(forRecipeId: id, context: viewContext)
            }
            viewContext.delete(recipe)
            PersistenceController.shared.save()
        }
    }
}


