import SwiftUI
import UIKit
import CoreData

struct AddGroceryItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var unit: IngredientUnit = .piece

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("Add Grocery Item")
                    .font(Theme.serifFont(24, italic: true))
                    .foregroundColor(Theme.onBackground)

                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(Theme.sansFont(11, weight: .bold))
                        .foregroundColor(Theme.onSurfaceVariant)
                        .tracking(1)
                    TextField("Item name", text: $name)
                        .font(Theme.sansFont(16))
                        .padding(12)
                        .background(Theme.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("QUANTITY")
                            .font(Theme.sansFont(11, weight: .bold))
                            .foregroundColor(Theme.onSurfaceVariant)
                            .tracking(1)
                        TextField("Optional", text: $quantity)
                            .font(Theme.sansFont(16))
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Theme.surfaceContainerLow)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("UNIT")
                            .font(Theme.sansFont(11, weight: .bold))
                            .foregroundColor(Theme.onSurfaceVariant)
                            .tracking(1)
                        Picker("Unit", selection: $unit) {
                            ForEach(IngredientUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.primary)
                    }
                }

                Button(action: save) {
                    Text("Add to List")
                        .font(Theme.sansFont(16, weight: .semiBold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primaryContainer)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Theme.primary.opacity(0.2), radius: 12, x: 0, y: 6)
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
                    .foregroundColor(Theme.primary)
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

        PersistenceController.shared.save()
        dismiss()
    }
}
