import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var sharedRecipePayload: SharedRecipePayload?
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeListView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
                .tag(0)

            GroceryListView()
                .tabItem {
                    Label("Groceries", systemImage: "basket")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(Color.accentTint)
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveSharedRecipe)) { notification in
            if let payload = notification.object as? SharedRecipePayload {
                sharedRecipePayload = payload
            }
        }
        .sheet(item: $sharedRecipePayload) { payload in
            SharedRecipePreviewView(payload: payload)
        }
    }
}

extension SharedRecipePayload: Identifiable {
    public var id: String { title + desc }
}
