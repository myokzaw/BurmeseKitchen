import SwiftUI
import UIKit
import CoreData

struct AddGroceryItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var unit: IngredientUnit = .piece
    @State private var selectedAisle: AisleCategory? = nil

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Add Grocery Item")
                    .font(.headlineLg)
                    .foregroundStyle(Color.primaryText)

                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(.labelXs)
                        .foregroundStyle(Color.secondaryText)
                        .tracking(1)
                    TextField("Item name", text: $name)
                        .font(.body)
                        .padding(12)
                        .background(Color.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Quantity + Unit row
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("QUANTITY")
                            .font(.labelXs)
                            .foregroundStyle(Color.secondaryText)
                            .tracking(1)
                        TextField("Optional", text: $quantity)
                            .font(.body)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color.cardFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("UNIT")
                            .font(.labelXs)
                            .foregroundStyle(Color.secondaryText)
                            .tracking(1)
                        Picker("Unit", selection: $unit) {
                            ForEach(IngredientUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.accentTint)
                    }
                }

                // Aisle picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("AISLE")
                        .font(.labelXs)
                        .foregroundStyle(Color.secondaryText)
                        .tracking(1)
                    HStack {
                        if let aisle = selectedAisle {
                            Label(aisle.displayName, systemImage: aisle.sfSymbol)
                                .font(.body)
                                .foregroundStyle(Color.primaryText)
                        } else {
                            Text("Don't categorise")
                                .font(.body)
                                .foregroundStyle(Color.tertiaryText)
                        }
                        Spacer()
                        Picker("Aisle", selection: $selectedAisle) {
                            Text("Don't categorise")
                                .tag(AisleCategory?.none)
                            ForEach(AisleCategory.allCases, id: \.self) { aisle in
                                Label(aisle.displayName, systemImage: aisle.sfSymbol)
                                    .tag(AisleCategory?.some(aisle))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.accentTint)
                        .labelsHidden()
                    }
                    .padding(12)
                    .background(Color.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Save button
                Button(action: save) {
                    Text("Add to List")
                        .font(.uiMd)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.plumDeep)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.plumDeep.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .disabled(name.isEmpty)

                Spacer()
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.accentTint)
            }
        }
    }

    private func save() {
        let item = GroceryItem(context: viewContext)
        item.id = UUID()
        item.name = name
        item.quantity = Double(quantity) ?? 0
        item.unit = unit.rawValue
        item.state = GroceryState.needed.rawValue
        item.addedAt = Date()
        item.aisleCategory = selectedAisle?.rawValue  // nil = ungrouped

        PersistenceController.shared.save()
        dismiss()
    }
}
