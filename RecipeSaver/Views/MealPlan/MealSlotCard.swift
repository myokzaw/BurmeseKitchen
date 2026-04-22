import SwiftUI
import CoreData

struct MealSlotCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject var viewModel: MealPlanViewModel

    let slot: MealSlot
    let date: Date

    // @FetchRequest for reactive CoreData updates — far more reliable than manual fetches
    @FetchRequest private var entries: FetchedResults<MealPlanEntry>

    @State private var showPicker = false

    init(slot: MealSlot, date: Date, viewModel: MealPlanViewModel) {
        self.slot = slot
        self.date = date
        self._viewModel = ObservedObject(wrappedValue: viewModel)

        let normalizedDate = Calendar.current.startOfDay(for: date)
        let req = NSFetchRequest<MealPlanEntry>(entityName: "MealPlanEntry")
        req.predicate = NSPredicate(
            format: "date == %@ AND mealSlot == %@",
            normalizedDate as NSDate,
            slot.rawValue
        )
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntry.addedAt, ascending: false)]
        self._entries = FetchRequest(fetchRequest: req, animation: .default)
    }

    private var entry: MealPlanEntry? { entries.first }

    var body: some View {
        if let entry = entry {
            filledCard(entry: entry)
        } else {
            emptyCard
        }
    }

    // MARK: - Empty State

    private var emptyCard: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: slot.icon)
                    .font(.uiMd)
                    .foregroundStyle(Color.tertiaryText)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.displayName)
                        .font(.bodyBold)
                        .foregroundStyle(Color.secondaryText)

                    if settings.showBurmese {
                        Text(slot.myanmarName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                Spacer()

                Image(systemName: "plus")
                    .font(.uiSm)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(14)
            .background(Color.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.divider, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            RecipePickerView(currentRecipeId: nil) { recipe in
                viewModel.setRecipe(recipe, date: date, slot: slot)
            }
        }
    }

    // MARK: - Filled State

    @ViewBuilder
    private func filledCard(entry: MealPlanEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: slot.icon)
                .font(.uiMd)
                .foregroundStyle(Color.accentTint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.recipeName ?? "")
                    .font(.bodyBold)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                // ServingsControl uses local @State to avoid Stepper glitches
                // that occur when the CoreData save triggers a @FetchRequest
                // re-render mid-gesture with a Binding(get:set:) pattern.
                ServingsControl(entry: entry, viewModel: viewModel)
                    .id(entry.objectID)
            }

            Spacer()

            // Delete button — tap area is independent of the card's onTapGesture
            Button {
                viewModel.removeEntry(entry)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.terra)
                    .frame(width: 36, height: 36)
                    .background(Color.terra.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primaryText.opacity(0.04), radius: 6, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showPicker = true
        }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.removeEntry(entry)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showPicker) {
            RecipePickerView(currentRecipeId: entry.recipeId) { recipe in
                viewModel.setRecipe(recipe, date: date, slot: slot)
            }
        }
    }
}

// MARK: - ServingsControl
// Separate view so @State survives @FetchRequest re-renders in the parent.
// Binds Stepper to local @State — immediately responsive, no CoreData feedback loop.
// .id(entry.objectID) on call site ensures fresh state when the entry is replaced.

private struct ServingsControl: View {
    let entry: MealPlanEntry
    let viewModel: MealPlanViewModel

    @State private var count: Int

    init(entry: MealPlanEntry, viewModel: MealPlanViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        self._count = State(initialValue: entry.servingsCount)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(count == 1 ? "1 serving" : "\(count) servings")
                .font(.bodySm)
                .foregroundStyle(Color.secondaryText)

            Stepper("", value: $count, in: 1...20)
                .labelsHidden()
                .scaleEffect(0.8, anchor: .leading)
        }
        .onChange(of: count) { newCount in
            viewModel.updateServings(newCount, for: entry)
        }
    }
}
