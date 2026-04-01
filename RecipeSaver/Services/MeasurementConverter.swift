import Foundation

// MARK: - Burmese Measurement Converter
// Hardcoded reference table. No CoreData — purely informational.

struct BurmeseMeasurement: Identifiable {
    let id = UUID()
    let informal: String         // Display name in English
    let burmese: String?         // Myanmar script label (nil if none)
    let standardValue: Double
    let standardUnit: String
    let notes: String
}

let burmeseMeasurements: [BurmeseMeasurement] = [
    BurmeseMeasurement(
        informal: "1 tin (condensed milk tin)",
        burmese: "တစ်ဗူး",
        standardValue: 397, standardUnit: "g",
        notes: "Standard 397g condensed milk tin, the universal measuring tool in Burmese kitchens"
    ),
    BurmeseMeasurement(
        informal: "1 coffee cup",
        burmese: "တစ်ခွက်",
        standardValue: 150, standardUnit: "ml",
        notes: "Burmese tea-house coffee cup, smaller than a Western mug"
    ),
    BurmeseMeasurement(
        informal: "1 rice bowl",
        burmese: "တစ်ဇွန်း",
        standardValue: 250, standardUnit: "ml",
        notes: "Standard rice bowl used as a measuring vessel"
    ),
    BurmeseMeasurement(
        informal: "1 handful (greens)",
        burmese: "တစ်ဆုပ်",
        standardValue: 30, standardUnit: "g",
        notes: "Approximate — leafy greens, herbs, noodles"
    ),
    BurmeseMeasurement(
        informal: "1 handful (rice)",
        burmese: "တစ်ဆုပ်",
        standardValue: 60, standardUnit: "g",
        notes: "Approximate — dry rice or grains"
    ),
    BurmeseMeasurement(
        informal: "1 tablespoon (Burmese)",
        burmese: "တစ်ဇွန်း",
        standardValue: 15, standardUnit: "ml",
        notes: "Equivalent to a standard Western tablespoon"
    ),
    BurmeseMeasurement(
        informal: "1 viss",
        burmese: "တစ်ဝိစ်",
        standardValue: 1632, standardUnit: "g",
        notes: "Traditional Burmese weight unit, used in markets for meat and produce"
    ),
    BurmeseMeasurement(
        informal: "1 pyi (dry goods)",
        burmese: "တစ်ပြည်",
        standardValue: 1040, standardUnit: "g",
        notes: "Traditional unit for dry goods like rice, beans, lentils"
    ),
    BurmeseMeasurement(
        informal: "Pinch (salt/spice)",
        burmese: "တစ်နယ်",
        standardValue: 0.5, standardUnit: "tsp",
        notes: "Two-finger pinch — salt, turmeric, spices"
    ),
    BurmeseMeasurement(
        informal: "1 coconut milk tin",
        burmese: nil,
        standardValue: 400, standardUnit: "ml",
        notes: "Standard 400ml coconut milk tin"
    ),
]
