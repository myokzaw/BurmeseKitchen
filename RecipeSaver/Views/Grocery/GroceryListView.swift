import SwiftUI
import CoreData

struct GroceryListView: View {
    @Environment(\.managedObjectContext) private var context

    @StateObject private var viewModel = GroceryListViewModel()

    // Single @FetchRequest for all items — grouping is done in the view model.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.addedAt, ascending: true)],
        animation: .default
    ) private var allItems: FetchedResults<GroceryItem>

    @State private var showAddItem = false

    private var boughtItems: [GroceryItem] {
        allItems.filter { $0.groceryState == .bought }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if allItems.isEmpty {
                    GroceryEmptyView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {

                            // Page title
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Groceries")
                                    .font(.displayMd)
                                    .foregroundStyle(Color.primaryText)
                                Text("Tap items to mark as bought")
                                    .font(.labelXs)
                                    .foregroundStyle(Color.tertiaryText)
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                            // Needed items — grouped by aisle
                            let groups = viewModel.groupedNeededItems(from: Array(allItems))
                            if !groups.isEmpty {
                                ForEach(groups, id: \.aisle?.rawValue) { group in
                                    AisleSectionHeader(aisle: group.aisle)
                                        .padding(.horizontal, 20)
                                    ForEach(group.items) { item in
                                        GroceryRowView(item: item, isBought: false)
                                            .onTapGesture { toggleItem(item) }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) { deleteItem(item) }
                                                label: { Label("Delete", systemImage: "trash") }
                                            }
                                    }
                                }
                            }

                            // Bought section
                            if !boughtItems.isEmpty {
                                GrocerySectionHeader(title: "Bought")
                                    .padding(.horizontal, 20)
                                ForEach(boughtItems) { item in
                                    GroceryRowView(item: item, isBought: true)
                                        .onTapGesture { toggleItem(item) }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) { deleteItem(item) }
                                            label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accentTint)
                    }
                }
                if !boughtItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear bought") { clearBought() }
                            .font(.uiSm)
                            .foregroundStyle(Color.terra)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                NavigationStack {
                    AddGroceryItemView()
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleItem(_ item: GroceryItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            item.state = item.groceryState == .needed
                ? GroceryState.bought.rawValue
                : GroceryState.needed.rawValue
            PersistenceController.shared.save()
        }
    }

    private func deleteItem(_ item: GroceryItem) {
        withAnimation {
            context.delete(item)
            PersistenceController.shared.save()
        }
    }

    private func clearBought() {
        withAnimation {
            boughtItems.forEach { context.delete($0) }
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Aisle section header

struct AisleSectionHeader: View {
    let aisle: AisleCategory?

    var body: some View {
        HStack(spacing: 6) {
            if let aisle {
                Image(systemName: aisle.sfSymbol)
                    .font(.system(size: 13, weight: .medium))
                Text(aisle.displayName.uppercased())
            } else {
                Image(systemName: "bag")
                    .font(.system(size: 13, weight: .medium))
                Text("Other".uppercased())
            }
        }
        .font(.uiMd)
        .foregroundStyle(Color.secondaryText)
        .tracking(1.2)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Section header (generic, used for Bought)

struct GrocerySectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.labelXs)
            .tracking(1.5)
            .foregroundStyle(Color.tertiaryText)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Grocery row

struct GroceryRowView: View {
    @ObservedObject var item: GroceryItem  // @ObservedObject — row re-renders the moment item.state changes
    let isBought: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isBought ? Color.plumDeep : Color.plumLight, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                if isBought {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.plumDeep)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isBought)

            // Name + quantity
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "")
                    .font(.bodyBold)
                    .foregroundStyle(isBought ? Color.tertiaryText : Color.primaryText)
                    .strikethrough(isBought, color: Color.tertiaryText)

                if let unit = item.unit, !unit.isEmpty, item.quantity > 0 {
                    Text("\(ScalingService.formatQuantity(item.quantity)) \(unit)")
                        .font(.bodySm)
                        .foregroundStyle(isBought ? Color.tertiaryText : Color.foliage)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(isBought ? Color.boughtFill : Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isBought ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isBought)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Empty state

struct GroceryEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "basket")
                .font(.system(size: 40))
                .foregroundStyle(Color.plumLight)
            Text("Your list is empty")
                .font(.headlineMd)
                .foregroundStyle(Color.primaryText)
            Text("Tap + to add items, or use \"Start shopping\" on any recipe.")
                .font(.bodySm)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
