import Combine
import Foundation

// MARK: - Settings Store
// Holds app-level preferences. Inject as .environmentObject at the root.

class SettingsStore: ObservableObject {

    @Published var showBurmese: Bool {
        didSet {
            UserDefaults.standard.set(showBurmese, forKey: "showBurmese")
        }
    }

    @Published var mealPlanWeekWindow: Int {
        didSet {
            let clamped = min(max(mealPlanWeekWindow, 1), 8)
            if clamped != mealPlanWeekWindow {
                mealPlanWeekWindow = clamped
            } else {
                UserDefaults.standard.set(clamped, forKey: "mealPlanWeekWindow")
            }
        }
    }

    init() {
        showBurmese = UserDefaults.standard.bool(forKey: "showBurmese")
        let stored = UserDefaults.standard.integer(forKey: "mealPlanWeekWindow")
        mealPlanWeekWindow = stored > 0 ? min(max(stored, 1), 8) : 3
    }

    static let shared = SettingsStore()
}
