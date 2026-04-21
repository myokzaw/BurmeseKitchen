import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var sharedRecipePayload: SharedRecipePayload?
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var bannerManager = BannerManager.shared

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack(alignment: .bottom) {
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

                MealPlanView(selectedTab: $selectedTab, context: viewContext)
                    .tabItem {
                        Label("Meal Plan", systemImage: "calendar")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(3)
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

            if let banner = bannerManager.current {
                FloatingBannerView(banner: banner, manager: bannerManager)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .environmentObject(bannerManager)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: bannerManager.current)
    }
}

extension SharedRecipePayload: Identifiable {
    public var id: String { title + desc }
}
