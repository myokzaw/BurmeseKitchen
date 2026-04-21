import CoreData
import Foundation

struct MealPlanService {

    // MARK: - Week date math (ISO 8601, Monday-first)

    static func weekStart(for date: Date, offset: Int = 0) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
        return cal.date(byAdding: .weekOfYear, value: offset, to: start)!
    }

    static func weekDates(for date: Date, offset: Int = 0) -> [Date] {
        let start = weekStart(for: date, offset: offset)
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    // MARK: - Fetch

    /// All entries for Mon–Sun of the week containing `date` + offset.
    static func entries(forWeekOf date: Date, offset: Int = 0, context: NSManagedObjectContext) -> [MealPlanEntry] {
        let dates = weekDates(for: date, offset: offset)
        guard let firstDay = dates.first, let lastDay = dates.last else { return [] }

        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let endOfLastDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: lastDay))!

        let req: NSFetchRequest<MealPlanEntry> = MealPlanEntry.fetchRequest()
        req.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            cal.startOfDay(for: firstDay) as NSDate,
            endOfLastDay as NSDate
        )
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntry.addedAt, ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    // MARK: - Upsert

    /// Replaces any existing entry for the same date+slot.
    static func setEntry(recipe: Recipe, date: Date, slot: MealSlot, servings: Int, context: NSManagedObjectContext) {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Remove existing entry for same date+slot
        let req: NSFetchRequest<MealPlanEntry> = MealPlanEntry.fetchRequest()
        req.predicate = NSPredicate(
            format: "date == %@ AND mealSlot == %@",
            normalizedDate as NSDate,
            slot.rawValue
        )
        if let existing = try? context.fetch(req) {
            existing.forEach { context.delete($0) }
        }

        let entry = MealPlanEntry(context: context)
        entry.id = UUID()
        entry.date = normalizedDate
        entry.mealSlot = slot.rawValue
        entry.recipeId = recipe.id ?? UUID()
        entry.recipeName = recipe.title ?? ""
        entry.servings = Int16(max(1, min(servings, 20)))
        entry.addedAt = Date()

        try? context.save()
    }

    // MARK: - Remove

    static func removeEntry(_ entry: MealPlanEntry, context: NSManagedObjectContext) {
        context.delete(entry)
        try? context.save()
    }

    /// Delete all MealPlanEntry rows for a given recipeId.
    /// Called from commitDelete in RecipeListViewModel after undo window expires.
    static func removeAllEntries(forRecipeId id: UUID, context: NSManagedObjectContext) {
        let req: NSFetchRequest<MealPlanEntry> = MealPlanEntry.fetchRequest()
        req.predicate = NSPredicate(format: "recipeId == %@", id as CVarArg)
        if let entries = try? context.fetch(req) {
            entries.forEach { context.delete($0) }
            try? context.save()
        }
    }

    // MARK: - Grocery Generation

    /// Generate grocery list from all entries in the selected week.
    /// Returns count of newly inserted GroceryItem records.
    @discardableResult
    static func generateGroceryList(
        forWeekOf date: Date,
        offset: Int = 0,
        mode: GroceryGenMode,
        replaceScope: ReplaceScope,
        context: NSManagedObjectContext
    ) -> Int {
        let weekEntries = entries(forWeekOf: date, offset: offset, context: context)
        guard !weekEntries.isEmpty else { return 0 }

        // Handle replace mode first
        if mode == .replace {
            switch replaceScope {
            case .recipeItemsOnly:
                let req: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
                req.predicate = NSPredicate(format: "sourceRecipeId != nil")
                if let items = try? context.fetch(req) {
                    items.forEach { context.delete($0) }
                }
                try? context.save()
            case .everything:
                let batchReq = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "GroceryItem"))
                try? context.execute(batchReq)
                context.reset()
            }
        }

        // Count items before insertion for delta
        let beforeReq: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let beforeCount = (try? context.count(for: beforeReq)) ?? 0

        // Fetch all recipes referenced by entries
        let recipeIds = Set(weekEntries.compactMap { $0.recipeId })
        let recipeReq: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeReq.predicate = NSPredicate(format: "id IN %@", recipeIds)
        let recipes = (try? context.fetch(recipeReq)) ?? []
        let recipeMap = Dictionary(uniqueKeysWithValues: recipes.compactMap { r in
            r.id.map { ($0, r) }
        })

        // Add each entry's ingredients to the grocery list
        for entry in weekEntries {
            guard let recipeId = entry.recipeId,
                  let recipe = recipeMap[recipeId] else { continue }
            let servings = entry.servingsCount
            GroceryMergeService.addRecipeToList(recipe: recipe, servings: servings, context: context)
        }

        let afterReq: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let afterCount = (try? context.count(for: afterReq)) ?? 0
        return max(0, afterCount - beforeCount)
    }
}
