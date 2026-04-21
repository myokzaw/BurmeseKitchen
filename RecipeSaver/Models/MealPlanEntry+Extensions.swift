import CoreData

extension MealPlanEntry {

    var mealSlotEnum: MealSlot {
        MealSlot(rawValue: mealSlot ?? "") ?? .dinner
    }

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date ?? Date())
    }

    var servingsCount: Int {
        Int(servings) > 0 ? Int(servings) : 1
    }
}
