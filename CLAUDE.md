# RecipeSaver — Master Context for Claude Code

> This file is the single source of truth for the RecipeSaver iOS app.
> Read this entire file before writing any code.

---

## 1. App Overview

**RecipeSaver** is an offline-first iOS recipe manager. Users can create, save, and share recipes, adjust serving sizes, and manage a grocery list tied to their recipes.

**Core problem it solves:** Users don't know what groceries they need to buy for a recipe. The app gives them a trackable shopping list so they can tick off what they already have and what they've bought.

---

## 2. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | Swift 5.10+ | |
| UI | SwiftUI | iOS 15+ minimum |
| Storage | CoreData | Offline-first, device-only |
| Minimum iOS | iOS 15 | No iCloud sync in v1 |
| Sharing | Custom URL scheme | `recipesaver://share?data=BASE64` |
| Auth | None | No accounts in v1 |
| Images | Local file system | `Documents/covers/` |

---

## 3. Full Requirements

### 3.1 Recipe list & discovery
- Toggle between grid view (photo-forward) and list view (compact)
- Live search bar filtering by recipe title
- Filter chips by meal category: breakfast, lunch, dinner, snack, dessert
- App ships with built-in starter recipes loaded on first launch (read-only, can be saved/customised)

### 3.2 Recipe creation & detail
- Metadata: title, description, meal category, difficulty, prep time, cook time
- Cover photo from camera roll or camera (stored locally)
- Ingredients list: each ingredient has name, quantity (Double), unit (String enum), sort order
- Step-by-step instructions: each step has body text and sort order, drag to reorder
- Serving size adjuster: base serving set on creation, stepper scales all ingredient quantities live using `ScalingService`
- "Start shopping" button generates a grocery list from current ingredients at current serving size

### 3.3 Sharing
- Share any recipe via iOS share sheet as a deep link URL
- Recipe is encoded as JSON → base64 → `recipesaver://share?data=BASE64`
- Receiver opens link → app shows `SharedRecipePreviewView` as full-screen sheet
- Recipient taps "Save to my recipes" → stored locally in CoreData
- No auth required, no server involved
- Images are NOT included in share links — shared recipes arrive without a cover photo

### 3.4 Grocery tracker
- Users manually add items to a persistent grocery list
- "Start shopping" on any recipe auto-populates list with recipe's ingredients at current serving size
- Multiple recipes can be added to the same list — duplicate ingredients with compatible units are merged
- Each item has three states:
  - `needed` — still need to buy (default)
  - `haveAtHome` — already have this ingredient at home
  - `bought` — picked up while shopping
- Tap an item to cycle its state
- Checked items are visually struck through but remain visible
- "Clear checked" action removes all non-`needed` items
- List persists across app launches exactly as left

### 3.5 General constraints
- Fully offline — no internet required for any feature in v1
- No user accounts, no login
- iPhone-first UI, iPad/Mac out of scope for v1
- Apple Watch companion (grocery list + recipe steps) is a planned v2 feature

---

## 4. CoreData Schema

### Entities

**Recipe**
```
id:              UUID        (required, set on creation)
title:           String
desc:            String
category:        String      (breakfast | lunch | dinner | snack | dessert)
difficulty:      String      (easy | medium | hard)
prepMinutes:     Integer16
cookMinutes:     Integer16
baseServings:    Integer16   (default: 1)
coverImagePath:  String?     (optional, local file path)
isBuiltIn:       Boolean     (true = read-only starter recipe)
createdAt:       Date
```

**Ingredient**
```
id:        UUID
name:      String
quantity:  Double       (base quantity at baseServings)
unit:      String       (cup | tbsp | tsp | g | oz | ml | piece | pinch | none)
sortOrder: Integer16
```

**RecipeStep**
```
id:        UUID
body:      String
sortOrder: Integer16
```

**GroceryItem**
```
id:             UUID
name:           String
quantity:       Double?     (optional)
unit:           String?     (optional)
state:          String      (needed | haveAtHome | bought)
sourceRecipeId: UUID?       (optional soft link — no CoreData relationship)
addedAt:        Date
```

### Relationships

| From | To | Type | Delete Rule |
|---|---|---|---|
| Recipe | ingredients (Ingredient) | One-to-many | Cascade |
| Recipe | steps (RecipeStep) | One-to-many | Cascade |
| Ingredient | recipe (Recipe) | Many-to-one inverse | Nullify |
| RecipeStep | recipe (Recipe) | Many-to-one inverse | Nullify |
| GroceryItem | — | No relationship | Soft link via sourceRecipeId |

### Codegen
Set **Codegen = Class Definition** on all four entities in the `.xcdatamodeld` inspector. Never edit the generated files — add logic via Swift extensions instead.

---

## 5. Swift Enums

```swift
// Enums.swift
enum MealCategory: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"
    case dessert   = "dessert"
}

enum Difficulty: String, CaseIterable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"
}

enum IngredientUnit: String, CaseIterable {
    case cup   = "cup"
    case tbsp  = "tbsp"
    case tsp   = "tsp"
    case grams = "g"
    case oz    = "oz"
    case ml    = "ml"
    case piece = "piece"
    case pinch = "pinch"
    case none  = "none"
}

enum GroceryState: String, CaseIterable {
    case needed     = "needed"
    case haveAtHome = "haveAtHome"
    case bought     = "bought"
}
```

---

## 6. PersistenceController

```swift
// CoreData/PersistenceController.swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "RecipeSaver")
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData failed to load: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { print("CoreData save error: \(error)") }
    }
}
```

---

## 7. CoreData Extensions

```swift
// CoreData/Recipe+Extensions.swift
import CoreData

extension Recipe {
    var sortedIngredients: [Ingredient] {
        (ingredients as? Set<Ingredient> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    var sortedSteps: [RecipeStep] {
        (steps as? Set<RecipeStep> ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    var mealCategory: MealCategory {
        MealCategory(rawValue: category ?? "") ?? .dinner
    }
    var difficultyLevel: Difficulty {
        Difficulty(rawValue: difficulty ?? "") ?? .easy
    }
}
```

```swift
// CoreData/GroceryItem+Extensions.swift
import CoreData

extension GroceryItem {
    var groceryState: GroceryState {
        GroceryState(rawValue: state ?? "") ?? .needed
    }
    var ingredientUnit: IngredientUnit {
        IngredientUnit(rawValue: unit ?? "") ?? .none
    }
}
```

---

## 8. Key Services

### ScalingService
Pure function — no state, no CoreData. Scales ingredient quantities and snaps to nice fractions.

```swift
// Services/ScalingService.swift
struct ScalingService {
    static func scale(quantity: Double, from base: Int, to target: Int) -> Double {
        let raw = quantity * Double(target) / Double(base)
        return roundToNiceFraction(raw)
    }

    private static func roundToNiceFraction(_ value: Double) -> Double {
        let fractions = [0.25, 0.33, 0.5, 0.67, 0.75]
        let whole = floor(value)
        let frac  = value - whole
        if frac < 0.1 { return whole }
        if frac > 0.9 { return whole + 1 }
        let nearest = fractions.min { abs($0 - frac) < abs($1 - frac) }!
        return whole + nearest
    }
}
```

### SharingService
Encodes/decodes recipes as base64 JSON deep links. Uses a separate `SharedRecipePayload` Codable struct — never passes NSManagedObject directly.

```swift
// Services/SharingService.swift
import Foundation

struct SharedRecipePayload: Codable {
    var title: String
    var desc: String
    var category: String
    var difficulty: String
    var prepMinutes: Int
    var cookMinutes: Int
    var baseServings: Int
    var ingredients: [SharedIngredient]
    var steps: [SharedStep]
}

struct SharedIngredient: Codable {
    var name: String
    var quantity: Double
    var unit: String
    var sortOrder: Int
}

struct SharedStep: Codable {
    var body: String
    var sortOrder: Int
}

struct SharingService {
    static func encode(recipe: Recipe) -> URL? {
        let payload = SharedRecipePayload(
            title: recipe.title ?? "",
            desc: recipe.desc ?? "",
            category: recipe.category ?? "",
            difficulty: recipe.difficulty ?? "",
            prepMinutes: Int(recipe.prepMinutes),
            cookMinutes: Int(recipe.cookMinutes),
            baseServings: Int(recipe.baseServings),
            ingredients: recipe.sortedIngredients.map {
                SharedIngredient(name: $0.name ?? "", quantity: $0.quantity,
                                 unit: $0.unit ?? "", sortOrder: Int($0.sortOrder))
            },
            steps: recipe.sortedSteps.map {
                SharedStep(body: $0.body ?? "", sortOrder: Int($0.sortOrder))
            }
        )
        guard let data = try? JSONEncoder().encode(payload),
              let base64 = data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "recipesaver://share?data=\(base64)") else { return nil }
        return url
    }

    static func decode(url: URL) -> SharedRecipePayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataParam) else { return nil }
        return try? JSONDecoder().decode(SharedRecipePayload.self, from: data)
    }
}
```

### GroceryMergeService
Maps recipe ingredients to GroceryItems. Merges same-name + same-unit items. Incompatible units create a separate item.

```swift
// Services/GroceryMergeService.swift
import CoreData

struct GroceryMergeService {
    static func addRecipeToList(recipe: Recipe, servings: Int, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let existing = (try? context.fetch(fetchRequest)) ?? []

        for ingredient in recipe.sortedIngredients {
            let scaledQty = ScalingService.scale(
                quantity: ingredient.quantity,
                from: Int(recipe.baseServings),
                to: servings
            )
            let unit = ingredient.unit ?? ""
            let name = ingredient.name ?? ""

            // Attempt to merge with existing item of same name + unit
            if let match = existing.first(where: {
                $0.name?.lowercased() == name.lowercased() && $0.unit == unit
            }) {
                match.quantity += scaledQty
            } else {
                let item = GroceryItem(context: context)
                item.id             = UUID()
                item.name           = name
                item.quantity       = scaledQty
                item.unit           = unit
                item.state          = GroceryState.needed.rawValue
                item.sourceRecipeId = recipe.id
                item.addedAt        = Date()
            }
        }
        try? context.save()
    }
}
```

### ImageStore
Saves/loads cover photos to `Documents/covers/`. Returns a file path string stored on `Recipe.coverImagePath`. Cleans up on recipe deletion.

```swift
// Services/ImageStore.swift
import UIKit

struct ImageStore {
    private static var coversURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let covers = docs.appendingPathComponent("covers", isDirectory: true)
        try? FileManager.default.createDirectory(at: covers, withIntermediateDirectories: true)
        return covers
    }

    static func save(image: UIImage, id: UUID) -> String? {
        let url = coversURL.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url)
        return url.path
    }

    static func load(path: String?) -> UIImage? {
        guard let path else { return nil }
        return UIImage(contentsOfFile: path)
    }

    static func delete(path: String?) {
        guard let path else { return }
        try? FileManager.default.removeItem(atPath: path)
    }
}
```

---

## 9. App Entry Point

```swift
// App/RecipeSaverApp.swift
import SwiftUI

@main
struct RecipeSaverApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              persistence.container.viewContext)
                .onOpenURL { url in
                    // Handle recipesaver://share?data=... deep links
                    NotificationCenter.default.post(
                        name: .didReceiveSharedRecipe,
                        object: SharingService.decode(url: url)
                    )
                }
        }
    }
}

extension Notification.Name {
    static let didReceiveSharedRecipe = Notification.Name("didReceiveSharedRecipe")
}
```

---

## 10. Navigation Structure

```
TabView (ContentView)
├── Tab 1: Recipes (RecipeListView)
│   ├── RecipeDetailView
│   │   └── CreateEditRecipeView (edit mode)
│   └── CreateEditRecipeView (create mode)
└── Tab 2: Grocery List (GroceryListView)
    └── AddGroceryItemView (sheet)

Modal (anywhere):
└── SharedRecipePreviewView (sheet, triggered by deep link)
```

### Tab bar items
```swift
// Tab 1
Label("Recipes", systemImage: "fork.knife")

// Tab 2
Label("Groceries", systemImage: "basket")
```

---

## 11. Screen Specifications

### RecipeListView
- `@FetchRequest` sorted by `createdAt` descending
- Search bar: `NSPredicate(format: "title CONTAINS[cd] %@", searchText)`
- Category filter: horizontal scroll of chip buttons, filters by `category` attribute
- Toggle button in toolbar: switches between `.grid` and `.list` display mode
- Grid: 2-column, each card shows cover photo, title, category chip, cook time
- List: each row shows small thumbnail, title, category, difficulty badge
- FAB or toolbar button to open `CreateEditRecipeView`
- Tap a recipe → `RecipeDetailView`

### RecipeDetailView
- Hero cover photo (full width, aspect 4:3)
- Title, description, metadata row (prep + cook time, difficulty, category)
- Serving size stepper (default = `recipe.baseServings`)
- Ingredients list: quantities scaled live via `ScalingService`
- Step-by-step instructions numbered list
- "Start shopping" button → calls `GroceryMergeService.addRecipeToList` then switches to grocery tab
- Share button → `ShareLink` with `SharingService.encode(recipe:)` URL
- Edit button → `CreateEditRecipeView` in edit mode
- Built-in recipes show "Save a copy" instead of "Edit"

### CreateEditRecipeView
- Multi-section form:
  1. Cover photo picker (PhotosPicker)
  2. Title + description fields
  3. Category picker (segmented or menu)
  4. Difficulty picker
  5. Prep time + cook time steppers
  6. Base servings stepper
  7. Ingredients section — add/remove/reorder rows
  8. Steps section — add/remove/reorder rows
- Save action calls `PersistenceController.shared.save()`
- Cancel confirms unsaved changes with an Alert

### GroceryListView
- `@FetchRequest` sorted by `addedAt` ascending
- Items grouped into three sections: "Still needed", "Have at home", "Bought"
- Tap item → cycle state: `needed → haveAtHome → bought → needed`
- Swipe to delete individual item
- Toolbar: "Clear checked" removes all `haveAtHome` and `bought` items
- "+" button → `AddGroceryItemView` sheet for manual item entry

### AddGroceryItemView
- Fields: name (required), quantity (optional Double), unit picker (optional)
- Save inserts new `GroceryItem` with state = `needed`

### SharedRecipePreviewView
- Shown as `.sheet` when deep link is opened
- Read-only preview of all recipe fields (no cover photo)
- "Save to my recipes" button → creates new `Recipe` in CoreData from `SharedRecipePayload`
- "Dismiss" button

---

## 12. Design System (Iris Garden)

The app uses the **"Botanical Editorial"** design language. Match this exactly.

### Colors
```swift
// All colors from the Iris Garden design system
let primary          = Color(hex: "#4f055d")   // Deep iris purple — high impact moments
let primaryContainer = Color(hex: "#692475")   // Slightly lighter purple
let primaryFixed     = Color(hex: "#ffd6fe")   // Light pink — chip backgrounds
let primaryFixedDim  = Color(hex: "#f8acff")   // Pink — input focus borders

let tertiary         = Color(hex: "#0f3412")   // Mossy dark green — icons, support elements
let tertiaryFixed    = Color(hex: "#c2eebb")   // Soft mint green — active chips, badges
let tertiaryFixedDim = Color(hex: "#a7d2a1")   // Muted sage

let surface          = Color(hex: "#fcfcd7")   // Warm cream — page background
let surfaceContainer = Color(hex: "#f0f0cc")   // Slightly deeper cream — cards
let surfaceContainerLow  = Color(hex: "#f6f6d1")
let surfaceContainerHigh = Color(hex: "#ebeac6")
let surfaceVariant   = Color(hex: "#e5e5c1")   // Progress bar backgrounds

let onBackground     = Color(hex: "#1c1d07")   // Near-black ink
let onSurface        = Color(hex: "#1c1d07")
let onSurfaceVariant = Color(hex: "#4f434e")   // Muted text
let outlineVariant   = Color(hex: "#d2c2cf")   // Ghost borders at 15% opacity

let secondary        = Color(hex: "#75527d")
let secondaryContainer = Color(hex: "#f8cbfe")
```

### Typography
```swift
// Headline / Display: Newsreader (serif) — storytelling moments
// Body / Label / UI: Manrope (sans-serif) — functional text

// Register custom fonts in Info.plist and add .ttf files to project
// Usage:
Font.custom("Newsreader-Italic", size: 34)   // Large titles
Font.custom("Newsreader-Regular", size: 24)  // Section headers
Font.custom("Manrope-SemiBold", size: 16)    // Body emphasis
Font.custom("Manrope-Regular", size: 14)     // Body / labels
Font.custom("Manrope-Bold", size: 11)        // Uppercase tracking labels
```

### Design rules
- **No sharp corners** — use `.cornerRadius(12)` minimum, `.clipShape(RoundedRectangle(cornerRadius: 20))` for cards
- **No hard borders** — use background color shifts for separation, not `stroke`
- **No pure black** — always use `onBackground` (#1c1d07) for text
- **Shadows:** `shadow(color: Color(hex: "#1c1d07").opacity(0.06), radius: 16, x: 0, y: 8)`
- **Glassmorphism** for top app bar and bottom nav: `.ultraThinMaterial` + backdrop blur
- **Active nav item:** `tertiaryFixed` background pill, `tertiary` text
- **Category chips:** `tertiaryFixed` fill when active, `surfaceContainerHigh` when inactive, `.capsule()` shape
- **Serif headlines lead, sans-serif body follows** — every screen should have a large italic serif title
- **Generous whitespace** — minimum 24pt padding on all screen edges

### Component patterns
```swift
// Top app bar
.background(.ultraThinMaterial)
.shadow(color: Color(hex: "#1c1d07").opacity(0.06), radius: 16, x: 0, y: 8)

// Bottom nav bar
.background(.ultraThinMaterial)
.shadow(color: Color(hex: "#1c1d07").opacity(0.04), radius: 12, x: 0, y: -4)

// Card / surface container
.background(Color(hex: "#f0f0cc"))
.clipShape(RoundedRectangle(cornerRadius: 16))
.shadow(color: Color(hex: "#1c1d07").opacity(0.05), radius: 12, x: 0, y: 6)

// Input field style
.background(Color(hex: "#f6f6d1"))
.overlay(alignment: .bottom) {
    Rectangle().fill(Color(hex: "#f8acff")).frame(height: 2) // focus indicator
}
.cornerRadius(8, corners: [.topLeft, .topRight])

// Primary CTA button
.background(Color(hex: "#692475"))
.foregroundColor(.white)
.clipShape(RoundedRectangle(cornerRadius: 16))
.shadow(color: Color(hex: "#4f055d").opacity(0.2), radius: 12, x: 0, y: 6)

// Grocery state colors
// needed    → default surface styling
// haveAtHome → tertiaryFixed tint background, strikethrough text
// bought    → surfaceVariant background, strikethrough text, reduced opacity
```

---

## 13. Starter Recipes JSON

Seed this file on first launch. Check `UserDefaults.standard.bool(forKey: "hasSeededRecipes")`.

```json
// Resources/StarterRecipes.json
[
  {
    "title": "Lavender Honey Tart",
    "desc": "A delicate shortbread crust holding a velvety honey custard, accented with wild lavender.",
    "category": "dessert",
    "difficulty": "medium",
    "prepMinutes": 20,
    "cookMinutes": 25,
    "baseServings": 6,
    "ingredients": [
      { "name": "Shortbread crust", "quantity": 1, "unit": "piece", "sortOrder": 0 },
      { "name": "Honey", "quantity": 3, "unit": "tbsp", "sortOrder": 1 },
      { "name": "Heavy cream", "quantity": 1, "unit": "cup", "sortOrder": 2 },
      { "name": "Dried lavender", "quantity": 1, "unit": "tsp", "sortOrder": 3 },
      { "name": "Egg yolks", "quantity": 3, "unit": "piece", "sortOrder": 4 }
    ],
    "steps": [
      { "body": "Preheat oven to 325°F. Press the shortbread crust into a tart pan and blind bake for 12 minutes.", "sortOrder": 0 },
      { "body": "Warm cream with lavender over low heat for 5 minutes. Strain out lavender.", "sortOrder": 1 },
      { "body": "Whisk together egg yolks and honey. Slowly stream in the warm cream, whisking constantly.", "sortOrder": 2 },
      { "body": "Pour custard into the pre-baked shell. Bake at 300°F for 20–25 minutes until just set.", "sortOrder": 3 }
    ]
  },
  {
    "title": "Rosemary Sea Salt Focaccia",
    "desc": "Hand-kneaded dough enriched with fresh garden rosemary and coarse sea salt.",
    "category": "dinner",
    "difficulty": "easy",
    "prepMinutes": 30,
    "cookMinutes": 25,
    "baseServings": 8,
    "ingredients": [
      { "name": "All-purpose flour", "quantity": 3, "unit": "cup", "sortOrder": 0 },
      { "name": "Warm water", "quantity": 1, "unit": "cup", "sortOrder": 1 },
      { "name": "Active dry yeast", "quantity": 1, "unit": "tsp", "sortOrder": 2 },
      { "name": "Olive oil", "quantity": 4, "unit": "tbsp", "sortOrder": 3 },
      { "name": "Fresh rosemary", "quantity": 2, "unit": "tbsp", "sortOrder": 4 },
      { "name": "Coarse sea salt", "quantity": 1, "unit": "tsp", "sortOrder": 5 }
    ],
    "steps": [
      { "body": "Dissolve yeast in warm water with a pinch of sugar. Let stand 5 minutes until foamy.", "sortOrder": 0 },
      { "body": "Combine flour, 2 tbsp olive oil, and yeast mixture. Knead 8 minutes until smooth.", "sortOrder": 1 },
      { "body": "Let dough rise 1 hour covered. Press into an oiled 9x13 pan. Dimple with fingers.", "sortOrder": 2 },
      { "body": "Drizzle remaining olive oil, scatter rosemary and sea salt. Bake at 425°F for 20–25 minutes.", "sortOrder": 3 }
    ]
  },
  {
    "title": "Wild Berry Salad",
    "desc": "A vibrant mix of woodland berries tossed in a light elderflower balsamic glaze.",
    "category": "breakfast",
    "difficulty": "easy",
    "prepMinutes": 10,
    "cookMinutes": 0,
    "baseServings": 2,
    "ingredients": [
      { "name": "Mixed berries", "quantity": 2, "unit": "cup", "sortOrder": 0 },
      { "name": "Elderflower cordial", "quantity": 1, "unit": "tbsp", "sortOrder": 1 },
      { "name": "Balsamic glaze", "quantity": 1, "unit": "tsp", "sortOrder": 2 },
      { "name": "Fresh mint", "quantity": 5, "unit": "piece", "sortOrder": 3 }
    ],
    "steps": [
      { "body": "Rinse and gently dry all berries.", "sortOrder": 0 },
      { "body": "Whisk together elderflower cordial and balsamic glaze.", "sortOrder": 1 },
      { "body": "Toss berries in glaze. Garnish with fresh mint leaves and serve immediately.", "sortOrder": 2 }
    ]
  }
]
```

---

## 14. File & Folder Structure

```
RecipeSaver/
├── App/
│   ├── RecipeSaverApp.swift
│   └── ContentView.swift              ← TabView root
├── CoreData/
│   ├── RecipeSaver.xcdatamodeld
│   ├── PersistenceController.swift
│   ├── Recipe+Extensions.swift
│   ├── Ingredient+Extensions.swift
│   └── GroceryItem+Extensions.swift
├── Models/
│   └── Enums.swift
├── Views/
│   ├── Recipes/
│   │   ├── RecipeListView.swift
│   │   ├── RecipeDetailView.swift
│   │   ├── CreateEditRecipeView.swift
│   │   └── SharedRecipePreviewView.swift
│   └── Grocery/
│       ├── GroceryListView.swift
│       └── AddGroceryItemView.swift
├── ViewModels/
│   ├── RecipeListViewModel.swift
│   ├── RecipeDetailViewModel.swift
│   └── GroceryListViewModel.swift
├── Services/
│   ├── SharingService.swift
│   ├── ScalingService.swift
│   ├── GroceryMergeService.swift
│   └── ImageStore.swift
└── Resources/
    └── StarterRecipes.json
```

---

## 15. Build Order

Build in this exact order. Each step must compile before proceeding.

1. `Enums.swift` + CoreData schema + `PersistenceController.swift`
2. CoreData extensions (`Recipe+Extensions`, `GroceryItem+Extensions`)
3. All service files (`ScalingService`, `SharingService`, `GroceryMergeService`, `ImageStore`)
4. Starter recipe seeding logic in `RecipeSaverApp.swift`
5. `RecipeListView` — read-only, `@FetchRequest`, no create yet
6. `RecipeDetailView` — display only, serving adjuster
7. `CreateEditRecipeView` — full form with photo picker
8. Sharing — `SharingService` encode + `onOpenURL` decode + `SharedRecipePreviewView`
9. `GroceryListView` — `@FetchRequest`, tap-to-cycle state
10. `AddGroceryItemView` + manual add
11. "Start shopping" — wire `GroceryMergeService` to `RecipeDetailView` button

---

## 16. Coding Rules for Claude Code

- **Never edit auto-generated CoreData files** — extend only via `+Extensions.swift` files
- **Always call `PersistenceController.shared.save()`** after any CoreData mutation
- **Never pass `NSManagedObject` to service classes** — map to plain Swift structs first
- **Store enums as `String` rawValue** in CoreData, convert at view model boundary
- **Use `@FetchRequest` in views** for simple static lists
- **Use `ObservableObject` view models** for screens with dynamic filtering (recipe list search, detail serving scaler)
- **Use `@StateObject`** when a view owns its view model, **`@ObservedObject`** when passed from parent
- **Use `@Environment(\.managedObjectContext)`** to access the context in views — never import the singleton directly in a view
- **Design language is non-negotiable** — all UI must match the Iris Garden botanical editorial system defined in Section 12
- **Offline-first** — never add any network calls, API integrations, or remote storage in v1
- **No `print` statements in production paths** — use them only for debug during development

---

*End of CLAUDE.md — RecipeSaver v1*
