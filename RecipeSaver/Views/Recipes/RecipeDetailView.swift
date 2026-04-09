import SwiftUI
import CoreData

// MARK: - CopyButtonState
enum CopyButtonState {
    case idle
    case copying
    case success
}

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var viewModel: RecipeDetailViewModel
    @Binding var selectedTab: Int

    @State private var showEditSheet = false
    @State private var showGroceryConfirmation = false
    @State private var showConverter = false
    @State private var showCookingMode = false
    @State private var expandedSubstitutionIngredientID: NSManagedObjectID? = nil

    // Copy button shimmer state
    @State private var copyButtonState: CopyButtonState = .idle

    let recipe: Recipe
    /// Called when the user taps delete (user recipes only). The parent view
    /// owns the delete flow (undo window, CoreData write) via RecipeListViewModel.
    let onDeleteRequested: (() -> Void)?

    init(recipe: Recipe, selectedTab: Binding<Int>, onDeleteRequested: (() -> Void)? = nil) {
        self.recipe = recipe
        self._selectedTab = selectedTab
        self.onDeleteRequested = onDeleteRequested
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {


                    // MARK: - Parallax hero
                    let heroHeight = UIScreen.main.bounds.width * (3.0 / 4.0)
                    GeometryReader { geo in
                        let globalOffset = geo.frame(in: .global).minY
                        // Scrolling up (offset < 0): shift image up at 0.5× speed
                        // Pulling down (offset > 0): stretch image downward (rubber-band)
                        let parallaxOffset = globalOffset > 0 ? -globalOffset : globalOffset * 0.5

                        RecipeHeroView(recipe: recipe)
                            .environmentObject(settings)
                            .offset(y: parallaxOffset)
                            .frame(
                                height: heroHeight + max(0, -parallaxOffset * 2),
                                alignment: .top
                            )
                    }
                    .frame(height: heroHeight)

                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Cultural note banner
                        if let note = recipe.culturalContext {
                            culturalNoteBanner(note)
                        }

                        // MARK: - Title + Myanmar script
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title ?? "")
                                .font(.displayMd)
                                .foregroundStyle(Color.primaryText)

                            if settings.showBurmese, let titleMy = recipe.titleMyanmar {
                                Text(titleMy)
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color.secondaryText)
                                    .lineSpacing(4)
                            }

                            if let desc = recipe.desc, !desc.isEmpty {
                                Text(desc)
                                    .font(.body)
                                    .foregroundStyle(Color.secondaryText)
                                    .padding(.top, 4)
                            }
                        }

                        // MARK: - Metadata pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                metaPill(icon: "clock", text: "\(recipe.prepMinutes)m prep")
                                metaPill(icon: "flame", text: "\(recipe.cookMinutes)m cook")
                                metaPill(icon: "chart.bar", text: recipe.difficultyLevel.rawValue.capitalized)
                                metaPill(icon: "mappin", text: recipe.recipeRegion)
                            }
                        }

                        // MARK: - Serving stepper
                        HStack {
                            Text("Servings")
                                .font(.bodyBold)
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    if viewModel.currentServings > 1 { viewModel.currentServings -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.accentTint)
                                }

                                Text("\(viewModel.currentServings)")
                                    .font(.bodyBold)
                                    .foregroundStyle(Color.primaryText)
                                    .frame(minWidth: 28)

                                Button {
                                    viewModel.currentServings += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.accentTint)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // MARK: - Ingredients
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.headlineLg)
                                .foregroundStyle(Color.primaryText)

                            ForEach(recipe.sortedIngredients, id: \.objectID) { ingredient in
                                ingredientRow(ingredient)
                            }
                        }

                        // MARK: - Spices
                        if !recipe.sortedSpices.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Spices & Seasonings")
                                    .font(.headlineLg)
                                    .foregroundStyle(Color.primaryText)

                                ForEach(Array(SpiceCategory.allCases.enumerated()), id: \.element) { _, category in
                                    let spicesInCategory = recipe.spicesByCategory[category] ?? []
                                    if !spicesInCategory.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(category.displayName)
                                                .font(.labelSm)
                                                .foregroundStyle(Color.secondaryText)
                                                .textCase(.uppercase)
                                                .tracking(0.5)

                                            ForEach(spicesInCategory, id: \.objectID) { spice in
                                                spiceRow(spice)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Steps
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Instructions")
                                .font(.headlineLg)
                                .italic()
                                .foregroundStyle(Color.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(Array(recipe.sortedSteps.enumerated()), id: \.element.objectID) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.labelSm)
                                        .foregroundStyle(Color.white)
                                        .frame(width: 26, height: 26)
                                        .background(Color.plumDeep)
                                        .clipShape(Circle())

                                    Text(step.body ?? "")
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(12)
                                .background(Color.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // MARK: - Nutrition estimates
                        if let nutrition = NutritionService.estimate(for: recipe, servings: viewModel.currentServings) {
                            DisclosureGroup("Nutrition Estimate per Serving") {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 0) {
                                        NutrientPill(label: "Calories", value: "~\(Int(nutrition.calories))", unit: "kcal")
                                        NutrientPill(label: "Protein",  value: "~\(Int(nutrition.proteinG))", unit: "g")
                                        NutrientPill(label: "Carbs",    value: "~\(Int(nutrition.carbsG))",   unit: "g")
                                        NutrientPill(label: "Fat",      value: "~\(Int(nutrition.fatG))",     unit: "g")
                                    }
                                    .padding(.top, 8)
                                    Text("Estimates based on \(nutrition.matchedCount) of \(nutrition.totalCount) ingredients. Values are approximate.")
                                        .font(.bodySm)
                                        .foregroundStyle(Color.tertiaryText)
                                }
                            }
                            .tint(Color.accentTint)
                            .font(.bodyBold)
                            .foregroundStyle(Color.primaryText)
                            .padding(14)
                            .background(Color.cardFill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // MARK: - Action buttons
                        HStack(spacing: 12) {
                            Button {
                                GroceryMergeService.addRecipeToList(
                                    recipe: recipe,
                                    servings: viewModel.currentServings,
                                    context: viewContext
                                )
                                selectedTab = 1
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "basket")
                                    Text("Start Shopping")
                                        .font(.uiMd)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.plumDeep)
                                .foregroundStyle(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showConverter = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler")
                                    Text("Converter")
                                        .font(.uiMd)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.adaptive(light: .terraPale, dark: Color(hex: "#3d1e0f")))
                                .foregroundStyle(Color.terra)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .padding(.bottom, 32)
            }
            .ignoresSafeArea(.container, edges: .top)

        }
        .onChange(of: copyButtonState) { _, newValue in
            if newValue == .success {
                // Reset shimmer after 2.4s
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        copyButtonState = .idle
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !recipe.sortedSteps.isEmpty {
                    Button {
                        showCookingMode = true
                    } label: {
                        Image(systemName: "flame")
                            .foregroundStyle(Color.terra)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if recipe.isBuiltIn {
                    // Copy button with shimmer state
                    Button {
                        saveBuiltInCopyWithFeedback()
                    } label: {
                        if copyButtonState == .success {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    Color.white,
                                    Color.adaptive(light: Color(hex: "#0f6e56"), dark: Color(hex: "#2ab891"))
                                )
                                .withShimmer()
                        } else {
                            Text("Save a Copy")
                        }
                    }
                    .font(.uiMd)
                    .foregroundStyle(Color.accentTint)
                    .buttonStyle(.plain)
                    .disabled(copyButtonState == .copying)
                } else if onDeleteRequested != nil {
                    // v3: delete button — delegates back to RecipeListView which owns the undo flow
                    Button {
                        dismiss()
                        onDeleteRequested?()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.accentTint)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !recipe.isBuiltIn {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.accentTint)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let shareURL = SharingService.encode(recipe: recipe) {
                    ShareLink(item: shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.accentTint)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                CreateEditRecipeView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showConverter) {
            MeasurementConverterView()
                .environmentObject(settings)
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func culturalNoteBanner(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.terra)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                Text("ABOUT THIS DISH")
                    .font(.labelXs)
                    .tracking(1.5)
                    .foregroundStyle(Color.terra)

                Text(note)
                    .font(.body)
                    .foregroundStyle(Color.primaryText)
            }
        }
        .padding(14)
        .background(Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func metaPill(icon: String, text: String) -> some View {
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

    @ViewBuilder
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name ?? "")
                        .font(.body)
                        .foregroundStyle(Color.primaryText)

                    if settings.showBurmese, let nameMy = ingredient.nameMyanmar {
                        Text(nameMy)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondaryText)
                            .lineSpacing(4)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(viewModel.formattedQuantity(for: ingredient)) \(ingredient.unit ?? "")")
                        .font(.bodyBold)
                        .foregroundStyle(Color.foliage)

                    if ingredient.hasSubstitutions {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if expandedSubstitutionIngredientID == ingredient.objectID {
                                    expandedSubstitutionIngredientID = nil
                                } else {
                                    expandedSubstitutionIngredientID = ingredient.objectID
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundStyle(Color.terra)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Substitution expansion panel
            if expandedSubstitutionIngredientID == ingredient.objectID {
                ForEach(ingredient.sortedSubstitutions, id: \.objectID) { sub in
                    substitutionPanel(sub)
                        .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func substitutionPanel(_ sub: IngredientSubstitution) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.terra)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                Text("SUBSTITUTION")
                    .font(.labelXs)
                    .tracking(1.5)
                    .foregroundStyle(Color.terra)

                Text(sub.noteText)
                    .font(.body)
                    .foregroundStyle(Color.primaryText)

                if !sub.contextText.isEmpty {
                    Text(sub.contextText)
                        .font(.bodySm)
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(14)
        .background(Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func spiceRow(_ spice: Spice) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(spice.displayName)
                    .font(.body)
                    .foregroundStyle(Color.primaryText)
            }

            Spacer()

            HStack(spacing: 6) {
                Text("\(spice.quantity > 0 ? String(format: "%.2f", spice.quantity).trimmingCharacters(in: CharacterSet(charactersIn: "0")) : "to taste") \(spice.unit ?? "")")
                    .font(.bodyBold)
                    .foregroundStyle(Color.terra)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - v3 copy with banner "View" button

    @discardableResult
    private func saveBuiltInCopyWithFeedback() -> Recipe {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            copyButtonState = .success
        }
        let copy = saveBuiltInCopy()

        BannerManager.shared.show(FloatingBanner(
            id: UUID(),
            title: "Saved to My Recipes",
            subtitle: "\"\(copy.title ?? "Recipe")\"",
            icon: "checkmark.circle.fill",
            accentColor: Color.foliage,
            actionLabel: "View",
            duration: 2.4,
            onAction: {
                NotificationCenter.default.post(name: .navigateToRecipe, object: copy)
            },
            onDismiss: nil
        ))
        return copy
    }

    @discardableResult
    private func saveBuiltInCopy() -> Recipe {
        let copy = Recipe(context: viewContext)
        copy.id          = UUID()
        copy.title       = (recipe.title ?? "") + " (My Copy)"
        copy.titleMy     = recipe.titleMy
        copy.desc        = recipe.desc
        copy.descMy      = recipe.descMy
        copy.category    = recipe.category
        copy.region      = recipe.region
        copy.difficulty  = recipe.difficulty
        copy.prepMinutes = recipe.prepMinutes
        copy.cookMinutes = recipe.cookMinutes
        copy.baseServings = recipe.baseServings
        copy.culturalNote = recipe.culturalNote
        copy.coverImagePath = recipe.coverImagePath
        copy.coverImageName = recipe.coverImageName
        copy.isCustomCoverImage = false
        copy.isBuiltIn   = false
        copy.createdAt   = Date()

        for ing in recipe.sortedIngredients {
            let newIng      = Ingredient(context: viewContext)
            newIng.id       = UUID()
            newIng.name     = ing.name
            newIng.nameMy   = ing.nameMy
            newIng.quantity = ing.quantity
            newIng.unit     = ing.unit
            newIng.sortOrder = ing.sortOrder
            newIng.recipe   = copy

            for sub in ing.sortedSubstitutions {
                let newSub = IngredientSubstitution(context: viewContext)
                newSub.id = UUID()
                newSub.note = sub.note
                newSub.context = sub.context
                newSub.sortOrder = sub.sortOrder
                newSub.ingredient = newIng
            }
        }

        for step in recipe.sortedSteps {
            let newStep      = RecipeStep(context: viewContext)
            newStep.id       = UUID()
            newStep.body     = step.body
            newStep.sortOrder = step.sortOrder
            newStep.recipe   = copy
        }

        for spice in recipe.sortedSpices {
            let newSpice      = Spice(context: viewContext)
            newSpice.id       = UUID()
            newSpice.name     = spice.name
            newSpice.quantity = spice.quantity
            newSpice.unit     = spice.unit
            newSpice.category = spice.category
            newSpice.sortOrder = spice.sortOrder
            newSpice.recipe   = copy
        }

        PersistenceController.shared.save()
        return copy
    }
}
// MARK: - NutrientPill

struct NutrientPill: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headlineMd)
                .foregroundStyle(Color.foliage)
            Text(unit)
                .font(.labelXs)
                .foregroundStyle(Color.tertiaryText)
            Text(label)
                .font(.labelSm)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

