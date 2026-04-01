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

    init() {
        showBurmese = UserDefaults.standard.bool(forKey: "showBurmese")
    }

    static let shared = SettingsStore()
}
