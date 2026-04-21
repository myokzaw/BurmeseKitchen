import SwiftUI
import CoreData
import Combine

class MealPlanViewModel: ObservableObject {

    @Published var weekOffset: Int = 0

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    // Mirrors SettingsStore.mealPlanWeekWindow
    var weekWindow: Int {
        SettingsStore.shared.mealPlanWeekWindow
    }

    var totalPages: Int { (weekWindow * 2) + 1 }

    var currentWeekStart: Date {
        MealPlanService.weekStart(for: Date(), offset: weekOffset)
    }

    var weekDates: [Date] {
        MealPlanService.weekDates(for: Date(), offset: weekOffset)
    }

    var weekRangeLabel: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    init(context: NSManagedObjectContext) {
        self.context = context

        // Observe weekWindow changes to clamp offset
        SettingsStore.shared.$mealPlanWeekWindow
            .dropFirst()
            .sink { [weak self] _ in
                self?.clampWeekOffset()
            }
            .store(in: &cancellables)
    }

    // MARK: - Entry Lookup

    func entry(for date: Date, slot: MealSlot) -> MealPlanEntry? {
        let allEntries = MealPlanService.entries(forWeekOf: Date(), offset: weekOffset, context: context)
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return allEntries.first {
            Calendar.current.startOfDay(for: $0.date ?? Date()) == normalizedDate &&
            $0.mealSlot == slot.rawValue
        }
    }

    func hasEntriesForCurrentWeek() -> Bool {
        !MealPlanService.entries(forWeekOf: Date(), offset: weekOffset, context: context).isEmpty
    }

    // MARK: - Mutations

    func setRecipe(_ recipe: Recipe, date: Date, slot: MealSlot) {
        MealPlanService.setEntry(
            recipe: recipe,
            date: date,
            slot: slot,
            servings: Int(recipe.baseServings),
            context: context
        )
    }

    func updateServings(_ servings: Int, for entry: MealPlanEntry) {
        entry.servings = Int16(max(1, min(servings, 20)))
        PersistenceController.shared.save()
    }

    func removeEntry(_ entry: MealPlanEntry) {
        MealPlanService.removeEntry(entry, context: context)
    }

    // MARK: - Grocery Generation

    /// Returns item count; caller shows FloatingBanner.
    func generateGroceryList(mode: GroceryGenMode, replaceScope: ReplaceScope) -> Int {
        MealPlanService.generateGroceryList(
            forWeekOf: Date(),
            offset: weekOffset,
            mode: mode,
            replaceScope: replaceScope,
            context: context
        )
    }

    // MARK: - Window Clamping

    func clampWeekOffset() {
        let limit = SettingsStore.shared.mealPlanWeekWindow
        let clamped = min(max(weekOffset, -limit), limit)
        if clamped != weekOffset {
            withAnimation { weekOffset = clamped }
        }
    }

    // MARK: - Grocery list state

    func groceryListIsEmpty() -> Bool {
        let req: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        req.fetchLimit = 1
        return (try? context.count(for: req)) ?? 0 == 0
    }

    func hasManualGroceryItems() -> Bool {
        let req: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        req.predicate = NSPredicate(format: "sourceRecipeId == nil")
        req.fetchLimit = 1
        return (try? context.count(for: req)) ?? 0 > 0
    }
}
