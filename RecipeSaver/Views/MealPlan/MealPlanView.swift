import SwiftUI
import CoreData

struct MealPlanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var settings: SettingsStore
    @Binding var selectedTab: Int

    @StateObject private var viewModel: MealPlanViewModel

    // Two-stage grocery generation confirmation
    @State private var showModeDialog = false
    @State private var showReplaceScopeDialog = false

    init(selectedTab: Binding<Int>, context: NSManagedObjectContext) {
        self._selectedTab = selectedTab
        self._viewModel = StateObject(wrappedValue: MealPlanViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sticky week header — pinned below nav bar
                weekHeader
                    .background(Color.appBackground)

                Divider().background(Color.divider)

                // Week page swiper
                TabView(selection: $viewModel.weekOffset) {
                    ForEach(-viewModel.weekWindow...viewModel.weekWindow, id: \.self) { offset in
                        WeekPageView(
                            offset: offset,
                            viewModel: viewModel,
                            onGenerate: { showModeDialog = true },
                            onGenerateDirect: { generateGrocery(mode: .merge, scope: .recipeItemsOnly) }
                        )
                        .environmentObject(settings)
                        .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: viewModel.weekOffset)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Meal Plan")
                        .font(.displayMd)
                        .foregroundStyle(Color.primaryText)
                }
            }
            .onChange(of: settings.mealPlanWeekWindow) { _ in
                viewModel.clampWeekOffset()
            }
        }
        .confirmationDialog("Generate Grocery List", isPresented: $showModeDialog, titleVisibility: .visible) {
            Button("Merge with existing list") {
                generateGrocery(mode: .merge, scope: .recipeItemsOnly)
            }
            Button("Replace existing list") {
                if viewModel.hasManualGroceryItems() {
                    showReplaceScopeDialog = true
                } else {
                    generateGrocery(mode: .replace, scope: .recipeItemsOnly)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Your list has items you added manually", isPresented: $showReplaceScopeDialog, titleVisibility: .visible) {
            Button("Replace recipe items only") {
                generateGrocery(mode: .replace, scope: .recipeItemsOnly)
            }
            Button("Replace everything", role: .destructive) {
                generateGrocery(mode: .replace, scope: .everything)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Week Header (sticky)

    private var weekHeader: some View {
        VStack(spacing: 10) {
            Text(viewModel.weekRangeLabel)
                .font(.bodyBold)
                .foregroundStyle(Color.secondaryText)
                .animation(.none, value: viewModel.weekOffset)

            weekBubbles
        }
        .padding(.vertical, 12)
    }

    private var weekBubbles: some View {
        HStack(spacing: 6) {
            ForEach(-viewModel.weekWindow...viewModel.weekWindow, id: \.self) { offset in
                bubble(for: offset)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.weekOffset = offset
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func bubble(for offset: Int) -> some View {
        let isActive = offset == viewModel.weekOffset
        let isThisWeek = offset == 0

        ZStack {
            if isActive {
                Capsule()
                    .fill(Color.accentTint)
                    .frame(width: 22, height: 8)
            } else if isThisWeek {
                Circle()
                    .strokeBorder(Color.accentTint, lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.divider)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 22, height: 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.weekOffset)
    }

    // MARK: - Grocery generation

    private func generateGrocery(mode: GroceryGenMode, scope: ReplaceScope) {
        let count = viewModel.generateGroceryList(mode: mode, replaceScope: scope)
        selectedTab = 1
        BannerManager.shared.show(FloatingBanner(
            id: UUID(),
            title: "Grocery list updated",
            subtitle: "\(count) item\(count == 1 ? "" : "s") added",
            icon: "cart.fill",
            accentColor: Color.accentTint,
            actionLabel: nil,
            duration: 3.0,
            onAction: nil,
            onDismiss: nil
        ))
    }
}

// MARK: - WeekPageView
// Separate struct so @FetchRequest can reactively track entries for this week

struct WeekPageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject var viewModel: MealPlanViewModel

    let offset: Int
    let onGenerate: () -> Void       // list has items → show dialog
    let onGenerateDirect: () -> Void // list is empty → generate immediately

    @FetchRequest private var weekEntries: FetchedResults<MealPlanEntry>

    init(offset: Int, viewModel: MealPlanViewModel,
         onGenerate: @escaping () -> Void,
         onGenerateDirect: @escaping () -> Void) {
        self.offset = offset
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onGenerate = onGenerate
        self.onGenerateDirect = onGenerateDirect

        let dates = MealPlanService.weekDates(for: Date(), offset: offset)
        let req = NSFetchRequest<MealPlanEntry>(entityName: "MealPlanEntry")
        if let first = dates.first, let last = dates.last {
            var cal = Calendar.current
            cal.firstWeekday = 2
            let startOfFirst = cal.startOfDay(for: first)
            let endOfLast = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: last))!
            req.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfFirst as NSDate,
                endOfLast as NSDate
            )
        }
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntry.addedAt, ascending: true)]
        self._weekEntries = FetchRequest(fetchRequest: req, animation: .default)
    }

    private var dates: [Date] {
        MealPlanService.weekDates(for: Date(), offset: offset)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(dates, id: \.self) { date in
                    MealPlanDayView(viewModel: viewModel, date: date)
                        .environmentObject(settings)
                }

                if weekEntries.isEmpty {
                    emptyState
                } else {
                    generateButton
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var generateButton: some View {
        Button {
            if viewModel.groceryListIsEmpty() {
                onGenerateDirect()
            } else {
                onGenerate()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cart.fill")
                Text("Generate Grocery List")
                    .font(.bodyBold)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentTint)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.accentTint.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentTint)

            Text("No meals planned")
                .font(.headlineMd)
                .foregroundStyle(Color.primaryText)

            Text("Add recipes to slots to get started")
                .font(.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}
