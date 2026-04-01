import CoreData

extension Spice {
    var spiceCategory: SpiceCategory {
        SpiceCategory(rawValue: category ?? "") ?? .driedSpices
    }
    
    var displayName: String {
        name ?? "Unknown Spice"
    }
    
    var displayQuantity: String {
        let qty = quantity
        let u = unit ?? ""
        
        if qty == 0 || u.isEmpty {
            return u.isEmpty ? "to taste" : u
        }
        
        // Format quantity nicely
        if qty == floor(qty) {
            return String(format: "%.0f %@", qty, u)
        } else {
            return String(format: "%.2f %@", qty, u).trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        }
    }
}
