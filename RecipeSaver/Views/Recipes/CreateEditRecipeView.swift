import SwiftUI
import PhotosUI
import UIKit
import CoreData

// MARK: - DeleteButtonState
enum DeleteButtonState {
    case idle
    case deleting
    case success
}

struct CreateEditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?

    @State private var title = ""
    @State private var desc = ""
    @State private var category: MealCategory = .dinner
    @State private var difficulty: Difficulty = .easy
    @State private var prepMinutes: Int = 10
    @State private var cookMinutes: Int = 15
    @State private var baseServings: Int = 2
    @State private var ingredientRows: [IngredientFormRow] = []
    @State private var stepRows: [StepFormRow] = []
    @State private var spiceRows: [SpiceFormRow] = []
    @State private var coverImage: UIImage?

    // Photo crop flow
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var rawImage: UIImage?
    @State private var showCropView = false
    @State private var imageRefreshToken: UUID = UUID()
    @State private var originalCoverImagePath: String?
    @State private var coverImageDidChange = false
    @State private var isLoadingSelectedPhoto = false
    // v3: focal point set during crop step 2
    @State private var pendingFocalPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)

    @State private var showDiscardAlert = false
    @State private var showDeleteConfirmation = false
    


    struct IngredientFormRow: Identifiable {
        let id = UUID()
        var name: String = ""
        var quantity: String = "1"
        var unit: IngredientUnit = .piece
        var substitutions: [SubstitutionFormRow] = []
    }

    struct SubstitutionFormRow: Identifiable {
        let id = UUID()
        var note: String = ""
        var context: String = ""
    }

    struct StepFormRow: Identifiable {
        let id = UUID()
        var body: String = ""
    }

    struct SpiceFormRow: Identifiable {
        let id = UUID()
        var name: String = ""
        var quantity: String = "1"
        var unit: IngredientUnit = .tsp
        var category: SpiceCategory = .driedSpices
    }

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Screen title
                    Text(recipe == nil ? "New Recipe" : "Edit Recipe")
                        .font(.displayMd)
                        .foregroundStyle(Color.primaryText)

                    // MARK: - Cover photo
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COVER PHOTO")
                            .font(.labelXs)
                            .tracking(1.5)
                            .foregroundStyle(Color.secondaryText)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.inputFill)
                                .frame(height: 200)

                            if let coverImage {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .aspectRatio(4 / 3, contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .id(imageRefreshToken)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.title2)
                                    Text("Add Cover Photo")
                                        .font(.body)
                                }
                                .foregroundStyle(Color.tertiaryText)
                            }

                            if isLoadingSelectedPhoto {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.25))
                                    .overlay {
                                        ProgressView()
                                            .tint(.white)
                                    }
                            }
                        }

                        // Photo selection buttons
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label(coverImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.fill")
                                    .font(.uiMd)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.plumDeep)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            if coverImage != nil {
                                Button {
                                    removeCoverImage()
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .font(.uiMd)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        // Helper text
                        if coverImage != nil {
                            Text("Your photo will appear in recipe lists and the detail view.")
                                .font(.bodySm)
                                .foregroundStyle(Color.secondaryText)
                                .padding(.top, 4)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        isLoadingSelectedPhoto = true
                        Task {
                            defer {
                                isLoadingSelectedPhoto = false
                                selectedPhotoItem = nil
                            }

                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let ui = UIImage(data: data) {
                                rawImage = ui
                                showCropView = true
                            }
                        }
                    }

                    // MARK: - Title
                    formField("TITLE") {
                        TextField("Recipe title", text: $title)
                            .font(.body)
                            .foregroundStyle(Color.primaryText)
                            .padding(12)
                            .background(Color.inputFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // MARK: - Description
                    formField("DESCRIPTION") {
                        TextField("Brief description", text: $desc, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(Color.primaryText)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.inputFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // MARK: - Category & Difficulty
                    HStack(spacing: 16) {
                        formField("CATEGORY") {
                            Picker("Category", selection: $category) {
                                ForEach(MealCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.accentTint)
                        }

                        formField("DIFFICULTY") {
                            Picker("Difficulty", selection: $difficulty) {
                                ForEach(Difficulty.allCases, id: \.self) { diff in
                                    Text(diff.rawValue.capitalized).tag(diff)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.accentTint)
                        }
                    }

                    // MARK: - Time & servings
                    VStack(spacing: 10) {
                        FormStepperRow(label: "Prep time (min)", value: $prepMinutes, range: 0...300)
                        FormStepperRow(label: "Cook time (min)", value: $cookMinutes, range: 0...600)
                        FormStepperRow(label: "Base servings", value: $baseServings, range: 1...50)
                    }

                    // MARK: - Ingredients
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingredients")
                            .font(.headlineLg)
                            .foregroundStyle(Color.primaryText)

                        ForEach($ingredientRows) { $row in
                            VStack(alignment: .leading, spacing: 6) {
                                // Ingredient row
                                HStack(spacing: 8) {
                                    TextField("Name", text: $row.name)
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)
                                        .frame(maxWidth: .infinity)

                                    TextField("Qty", text: $row.quantity)
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)
                                        .frame(width: 50)
                                        .keyboardType(.decimalPad)

                                    Picker("Unit", selection: $row.unit) {
                                        ForEach(IngredientUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.accentTint)

                                    Button {
                                        ingredientRows.removeAll { $0.id == row.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.tertiaryText)
                                    }
                                }
                                .padding(10)
                                .background(Color.inputFill)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                // Substitution rows
                                ForEach($row.substitutions) { $sub in
                                    HStack(alignment: .top, spacing: 0) {
                                        Rectangle()
                                            .fill(Color.terra)
                                            .frame(width: 3)
                                            .clipShape(RoundedRectangle(cornerRadius: 1.5))
                                            .padding(.trailing, 10)

                                        VStack(alignment: .leading, spacing: 6) {
                                            TextField("Substitute ingredient", text: $sub.note)
                                                .font(.body)
                                                .foregroundStyle(Color.primaryText)

                                            TextField("Context (when to use)", text: $sub.context)
                                                .font(.bodySm)
                                                .foregroundStyle(Color.secondaryText)
                                        }
                                        .padding(.vertical, 8)

                                        Spacer()

                                        Button {
                                            row.substitutions.removeAll { $0.id == sub.id }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(Color.tertiaryText)
                                                .padding(.top, 8)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .background(Color.adaptive(light: .terraPale, dark: Color(hex: "#2a1208")))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                Button {
                                    row.substitutions.append(SubstitutionFormRow())
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Add substitution")
                                            .font(.uiSm)
                                    }
                                    .foregroundStyle(Color.terra)
                                    .padding(.leading, 4)
                                }
                            }
                        }

                        Button {
                            ingredientRows.append(IngredientFormRow())
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Ingredient")
                                    .font(.bodyBold)
                            }
                            .foregroundStyle(Color.accentTint)
                        }
                    }

                    // MARK: - Spices
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Spices & Seasonings")
                            .font(.headlineLg)
                            .foregroundStyle(Color.primaryText)

                        ForEach($spiceRows) { $row in
                            HStack(spacing: 8) {
                                TextField("Spice name", text: $row.name)
                                    .font(.body)
                                    .foregroundStyle(Color.primaryText)
                                    .frame(maxWidth: .infinity)

                                TextField("Qty", text: $row.quantity)
                                    .font(.body)
                                    .foregroundStyle(Color.primaryText)
                                    .frame(width: 50)
                                    .keyboardType(.decimalPad)

                                Picker("Unit", selection: $row.unit) {
                                    ForEach(IngredientUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.accentTint)
                                .frame(width: 80)

                                Picker("Cat", selection: $row.category) {
                                    ForEach(SpiceCategory.allCases, id: \.self) { category in
                                        Text(category.displayName).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.terra)
                                .frame(width: 60)

                                Button {
                                    spiceRows.removeAll { $0.id == row.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.tertiaryText)
                                }
                            }
                            .padding(10)
                            .background(Color.inputFill)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            spiceRows.append(SpiceFormRow())
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Spice")
                                    .font(.bodyBold)
                            }
                            .foregroundStyle(Color.accentTint)
                        }
                    }

                    // MARK: - Steps
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Steps")
                            .font(.headlineLg)
                            .foregroundStyle(Color.primaryText)

                        ForEach(Array($stepRows.enumerated()), id: \.element.id) { index, $step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.labelSm)
                                    .foregroundStyle(Color.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.plumDeep)
                                    .clipShape(Circle())
                                    .padding(.top, 8)

                                TextField("Step description", text: $step.body, axis: .vertical)
                                    .font(.body)
                                    .foregroundStyle(Color.primaryText)
                                    .lineLimit(2...5)
                                    .frame(maxWidth: .infinity)

                                Button {
                                    stepRows.removeAll { $0.id == step.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.tertiaryText)
                                }
                                .padding(.top, 8)
                            }
                            .padding(10)
                            .background(Color.inputFill)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            stepRows.append(StepFormRow())
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                                    .font(.bodyBold)
                            }
                            .foregroundStyle(Color.accentTint)
                        }
                    }

                    // MARK: - Save button
                    Button(action: saveRecipe) {
                        Text("Save Recipe")
                            .font(.uiMd)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.plumDeep)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.plumDeep.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.5 : 1)

                    // Delete recipe — only shown for user-created recipes (never built-ins)
                    if let recipe, !recipe.isBuiltIn {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.divider)
                                .padding(.vertical, 24)

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                    Text("Delete this recipe")
                                        .font(.uiMd)
                                }
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.bottom, 16)
                        }
                        .confirmationDialog(
                            "Delete \"\(recipe.title ?? "this recipe")\"?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Delete recipe", role: .destructive) { deleteRecipeWithFeedback() }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This cannot be undone. The recipe and its cover photo will be permanently removed.")
                        }
                    }
                }
                .padding(20)
            }

        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundStyle(Color.accentTint)
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes that will be lost.")
        }
        .fullScreenCover(isPresented: $showCropView) {
            if let raw = rawImage {
                ImageCropView(
                    image: raw,
                    onConfirm: { cropped, focal in
                        coverImage = cropped
                        pendingFocalPoint = focal
                        coverImageDidChange = true
                        imageRefreshToken = UUID()
                        showCropView = false
                        rawImage = nil
                    },
                    onCancel: {
                        showCropView = false
                        rawImage = nil
                    }
                )
            }
        }
        .onAppear { loadExistingRecipe() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.labelXs)
                .foregroundStyle(Color.tertiaryText)
                .tracking(1.5)
            content()
        }
    }

    private var hasUnsavedChanges: Bool {
        !title.isEmpty || !desc.isEmpty || !ingredientRows.isEmpty || !stepRows.isEmpty || coverImageDidChange
    }

    private func loadExistingRecipe() {
        guard let recipe else { return }
        title         = recipe.title ?? ""
        desc          = recipe.desc ?? ""
        category      = recipe.mealCategory
        difficulty    = recipe.difficultyLevel
        prepMinutes   = Int(recipe.prepMinutes)
        cookMinutes   = Int(recipe.cookMinutes)
        baseServings  = Int(recipe.baseServings)
        originalCoverImagePath = recipe.coverImagePath

        // Load image: prefer custom if available, fall back to default asset
        if recipe.isCustomCoverImage, let path = recipe.coverImagePath {
            coverImage = ImageStore.load(path: path)
        } else if !recipe.isCustomCoverImage, let assetName = recipe.coverImageName {
            coverImage = UIImage(named: "Starter\(assetName)")
        }

        ingredientRows = recipe.sortedIngredients.map { ing in
            IngredientFormRow(
                name: ing.name ?? "",
                quantity: ing.quantity == floor(ing.quantity)
                    ? String(format: "%.0f", ing.quantity)
                    : String(ing.quantity),
                unit: IngredientUnit(rawValue: ing.unit ?? "") ?? .piece,
                substitutions: ing.sortedSubstitutions.map { sub in
                    SubstitutionFormRow(note: sub.noteText, context: sub.contextText)
                }
            )
        }

        stepRows = recipe.sortedSteps.map { step in
            StepFormRow(body: step.body ?? "")
        }

        spiceRows = recipe.sortedSpices.map { spice in
            SpiceFormRow(
                name: spice.name ?? "",
                quantity: spice.quantity == floor(spice.quantity)
                    ? String(format: "%.0f", spice.quantity)
                    : String(spice.quantity),
                unit: IngredientUnit(rawValue: spice.unit ?? "") ?? .tsp,
                category: spice.spiceCategory
            )
        }
    }

    private func saveRecipe() {
        let target: Recipe
        if let recipe {
            target = recipe
            for ing in recipe.sortedIngredients { viewContext.delete(ing) }
            for step in recipe.sortedSteps { viewContext.delete(step) }
            for spice in recipe.sortedSpices { viewContext.delete(spice) }
        } else {
            target = Recipe(context: viewContext)
            target.id        = UUID()
            target.createdAt = Date()
            target.isBuiltIn = false
            target.isCustomCoverImage = false
        }

        target.title       = title
        target.desc        = desc
        target.category    = category.rawValue
        target.difficulty  = difficulty.rawValue
        target.prepMinutes = Int16(prepMinutes)
        target.cookMinutes = Int16(cookMinutes)
        target.baseServings = Int16(baseServings)

        if coverImageDidChange, let existingPath = target.coverImagePath, let newCoverImage = coverImage {
            let newPath = ImageStore.save(image: newCoverImage, id: target.id ?? UUID())
            if let newPath {
                if existingPath != newPath {
                    ImageStore.delete(path: existingPath)
                }
                target.coverImagePath = newPath
                target.isCustomCoverImage = true
            }
        } else if coverImageDidChange, coverImage == nil {
            ImageStore.delete(path: target.coverImagePath)
            target.coverImagePath = nil
            target.isCustomCoverImage = false
        } else if let img = coverImage, target.coverImagePath == nil {
            let imageId = target.id ?? UUID()
            if let path = ImageStore.save(image: img, id: imageId) {
                target.coverImagePath = path
                target.isCustomCoverImage = true
            }
        }

        // v3: persist focal point whenever a custom image is set
        if coverImageDidChange && coverImage != nil {
            target.cropFocalX = pendingFocalPoint.x
            target.cropFocalY = pendingFocalPoint.y
        }

        for (index, row) in ingredientRows.enumerated() {
            guard !row.name.isEmpty else { continue }
            let ing       = Ingredient(context: viewContext)
            ing.id        = UUID()
            ing.name      = row.name
            ing.quantity  = Double(row.quantity) ?? 0
            ing.unit      = row.unit.rawValue
            ing.sortOrder = Int16(index)
            ing.recipe    = target

            for (subIndex, subRow) in row.substitutions.enumerated() {
                guard !subRow.note.isEmpty else { continue }
                let sub       = IngredientSubstitution(context: viewContext)
                sub.id        = UUID()
                sub.note      = subRow.note
                sub.context   = subRow.context
                sub.sortOrder = Int16(subIndex)
                sub.ingredient = ing
            }
        }

        for (index, row) in stepRows.enumerated() {
            guard !row.body.isEmpty else { continue }
            let step       = RecipeStep(context: viewContext)
            step.id        = UUID()
            step.body      = row.body
            step.sortOrder = Int16(index)
            step.recipe    = target
        }

        for (index, row) in spiceRows.enumerated() {
            guard !row.name.isEmpty else { continue }
            let spice      = Spice(context: viewContext)
            spice.id       = UUID()
            spice.name     = row.name
            spice.quantity = Double(row.quantity) ?? 0
            spice.unit     = row.unit.rawValue
            spice.category = row.category.rawValue
            spice.sortOrder = Int16(index)
            spice.recipe   = target
        }

        PersistenceController.shared.save()
        dismiss()
    }

    private func removeCoverImage() {
        coverImage = nil
        coverImageDidChange = true
        imageRefreshToken = UUID()
    }

    // MARK: - Delete with enhanced feedback

    private func deleteRecipeWithFeedback() {
        guard let recipe else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let context = viewContext
        let imagePath = recipe.coverImagePath
        let recipeTitle = recipe.title ?? "Recipe"
        dismiss()

        BannerManager.shared.show(FloatingBanner(
            id: UUID(),
            title: "\"\(recipeTitle)\" deleted",
            subtitle: "Tap Undo to restore",
            icon: "trash.fill",
            accentColor: Color.accentTint,
            actionLabel: "Undo",
            duration: 3.0,
            onAction: nil,
            onDismiss: {
                ImageStore.delete(path: imagePath)
                context.delete(recipe)
                PersistenceController.shared.save()
            }
        ))
    }
}

// MARK: - Form Stepper Row

struct FormStepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.primaryText)
            Spacer()
            HStack(spacing: 14) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Color.accentTint)
                }

                Text("\(value)")
                    .font(.bodyBold)
                    .foregroundStyle(Color.primaryText)
                    .frame(minWidth: 28)

                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentTint)
                }
            }
        }
        .padding(12)
        .background(Color.inputFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
