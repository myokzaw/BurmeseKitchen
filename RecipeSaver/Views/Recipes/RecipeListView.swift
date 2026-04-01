import SwiftUI
import CoreData

struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel = RecipeListViewModel()
    @Binding var selectedTab: Int
    @State private var feedbackBanner: RecipeFeedbackBannerData?

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
            return matchesSearch && matchesCategory
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
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, selectedTab: $selectedTab)) {
                                        RecipeGridCard(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredRecipes, id: \.objectID) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe, selectedTab: $selectedTab)) {
                                        RecipeListCard(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }

                if let feedbackBanner {
                    VStack {
                        RecipeFeedbackBanner(data: feedbackBanner)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
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
            .onReceive(NotificationCenter.default.publisher(for: .recipeFeedbackEvent)) { notification in
                guard
                    let actionRaw = notification.userInfo?["action"] as? String,
                    let action = RecipeFeedbackAction(rawValue: actionRaw),
                    let title = notification.userInfo?["title"] as? String
                else { return }

                showFeedbackBanner(for: action, title: title)
            }
        }
    }

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

    private func showFeedbackBanner(for action: RecipeFeedbackAction, title: String) {
        let data = RecipeFeedbackBannerData(
            title: action == .copied ? "Saved to My Recipes" : "Recipe Deleted",
            message: action == .copied ? "\"\(title)\" is ready to edit." : "\"\(title)\" was removed from your collection.",
            icon: action == .copied ? "square.and.arrow.down.fill" : "trash.fill",
            accent: action == .copied ? .foliage : .terra
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            feedbackBanner = data
        }

        Task {
            try? await Task.sleep(for: .seconds(2.4))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if feedbackBanner?.title == data.title && feedbackBanner?.message == data.message {
                        feedbackBanner = nil
                    }
                }
            }
        }
    }
}

private struct RecipeFeedbackBannerData: Equatable {
    let title: String
    let message: String
    let icon: String
    let accent: Color
}

private struct RecipeFeedbackBanner: View {
    let data: RecipeFeedbackBannerData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: data.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 32, height: 32)
                .background(data.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(data.title)
                    .font(.bodyBold)
                    .foregroundStyle(Color.primaryText)
                Text(data.message)
                    .font(.bodySm)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.divider, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}
