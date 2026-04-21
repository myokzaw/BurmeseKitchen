# Burmese Kitchen — v4 Master Context for Claude Code

> **Reading order — both files required:**
> 1. `CLAUDE_v4.md` (this file) — complete standalone spec through v4
> 2. `DESIGN.md` — Royal Plum color system, full-bleed scrim, dark mode rules
>
> Do not write any UI code until both files have been read.
> `DESIGN.md` overrides any color, typography, or photo layout decision in this file.

---

## 1. App Identity & Overview

**Display name:** Burmese Kitchen
**Bundle ID:** myozaw.RecipeSaver
**Target audience:** Burmese diaspora cooking at home abroad

**Five problems solved:**
1. Hard-to-find ingredients → inline substitution system
2. Informal measurements ("a tin", "a handful") → built-in converter
3. No curated Burmese recipe library → 20 hand-crafted starter recipes
4. No weekly meal planning → weekly plan with one-tap grocery generation
5. No planning horizon control → configurable week window (1–8 weeks)

---

## 2. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | Swift 5.10+ | |
| UI | SwiftUI | iOS 15+ minimum |
| Storage | CoreData | Offline-first, device-only |
| Minimum iOS | iOS 15 | No iCloud sync |
| Sharing | Custom URL scheme | `recipesaver://share?data=BASE64` |
| Auth | None | No accounts |
| Images | Local file system | `Documents/covers/` (relative paths) |

---

## 3. Full Feature Set

### v1 — Recipe Manager Foundation
- Recipe creation, editing, deletion (with 3-second undo)
- Serving size adjuster — live-scaling via `ScalingService`
- Grocery list — auto-populated from recipe ingredients, tap to cycle state
- Deep-link sharing — JSON → base64 URL, no server

### v2 — Burmese Kitchen Identity
- 20-recipe Burmese starter library with seeding
- Ingredient substitution system (inline, expandable)
- Informal Burmese measurement converter
- English / Myanmar bilingual toggle
- Royal Plum design system + full-bleed scrim photos
- In-app photo crop (`ImageCropView`)
- Spices & Seasonings section (grouped by category, scales with servings)
- Recipe management: copy built-in / edit user recipe / delete

### v3 — Polish & Power-User
- Crop-to-fill image rendering with focal point anchor
- Parallax hero on `RecipeDetailView`
- Cooking Mode — full-screen swipeable steps, screen always on
- Aisle grouping in `GroceryListView`
- Offline nutrition estimates (`NutritionService`, ~80 ingredient database)
- Floating action banner with Undo (delete) and View (copy) actions
- Optimistic delete — 3-second undo window, no confirmation dialog
- Versioned incremental content updates (`StarterContentUpdates.json`)

### v4 — Weekly Meal Plan
- 4th tab: "Meal Plan" (`calendar` SF symbol)
- Configurable week window: 1–8 weeks past/future, set in Settings
- 7-day weekly view, swipe left/right between weeks (ISO 8601, Monday-first)
- 4 named slots per day: Breakfast, Lunch, Dinner, Snack — 1 recipe each
- Per-slot serving count (stepper inline on card, persisted, min 1 max 20)
- Tap empty slot → `RecipePickerView` sheet to assign a recipe
- Tap filled slot → replace recipe; long-press → "Remove" context menu
- Currently assigned recipe shown with checkmark in `RecipePickerView`
- "Generate Grocery List" button → two-stage confirmation (mode + replace scope)
- Merge keeps existing items and adds plan ingredients (deduplicating same name+unit+sourceRecipeId)
- Replace: choose "Replace recipe items only" or "Replace everything"
- Same recipe in multiple slots → separate grocery rows per slot
- After generation, app switches to Groceries tab + shows `FloatingBannerView` with item count
- All entries persist in CoreData across app launches
- MealPlanEntry slots preserved (not deleted) during recipe's 3-second undo window; cleaned up on commit

---

## 4. CoreData Schema

Current model version: **`RecipeSaver 4.xcdatamodel`**
Lightweight migration is enabled — all new fields have defaults, no mapping model needed.

### Recipe

```
id:                UUID        (required)
title:             String?
titleMy:           String?     (Myanmar script title)
desc:              String?
descMy:            String?     (Myanmar script description)
category:          String?     (breakfast|lunch|dinner|snack|dessert|noodles|curry|salad|soup|ceremonial)
region:            String?     (e.g. "Shan State", "Mandalay", "Nationwide")
difficulty:        String?     (easy|medium|hard)
prepMinutes:       Integer16   (default: 0)
cookMinutes:       Integer16   (default: 0)
baseServings:      Integer16   (default: 1)
coverImagePath:    String?     (relative path: "covers/UUID.jpg" — custom user photos)
coverImageName:    String?     (asset catalog name — built-in images, e.g. "StarterMohinga")
isCustomCoverImage: Boolean
culturalNote:      String?
isBuiltIn:         Boolean     (true = read-only starter recipe)
createdAt:         Date?
cropFocalX:        Double      (default: 0.5 — horizontal focal point 0.0–1.0)
cropFocalY:        Double      (default: 0.5 — vertical focal point 0.0–1.0)
```

### Ingredient

```
id:        UUID
name:      String?
nameMy:    String?     (Myanmar script)
quantity:  Double      (base quantity at recipe.baseServings)
unit:      String?
sortOrder: Integer16
```

Relationships: `recipe` (many-to-one, nullify), `substitutions` → IngredientSubstitution (one-to-many, cascade)

### IngredientSubstitution

```
id:        UUID
note:      String?     (e.g. "Tinned mackerel or sardines")
context:   String?     (e.g. "If catfish is unavailable abroad")
sortOrder: Integer16
```

Relationship: `ingredient` (many-to-one, nullify)

### Spice

```
id:        UUID
name:      String?
quantity:  Double
unit:      String?
category:  String?     (driedSpices|freshHerbs|spiceBlends|heatElements|aromatics)
sortOrder: Integer16
```

Relationship: `recipe` (many-to-one, nullify)

### RecipeStep

```
id:        UUID
body:      String?
sortOrder: Integer16
```

Relationship: `recipe` (many-to-one, nullify)

### GroceryItem

```
id:               UUID
name:             String?
quantity:         Double?
unit:             String?
state:            String?     (needed|bought)
aisleCategory:    String?     (rawValue of AisleCategory enum — v3)
sourceRecipeId:   UUID?       (soft link, no CoreData relationship)
sourceRecipeName: String?
addedAt:          Date?
```

### MealPlanEntry *(new in v4)*

```
id:          UUID        (required)
date:        Date        (normalized to midnight / start of day)
mealSlot:    String      (breakfast|lunch|dinner|snack)
recipeId:    UUID        (soft link to Recipe.id — no CoreData relationship)
recipeName:  String      (denormalized — survives recipe deletion)
servings:    Integer16   (default: recipe.baseServings at time of assignment, min 1 max 20)
addedAt:     Date        (for ordering)
```

No relationship to Recipe — same soft-link pattern as `GroceryItem.sourceRecipeId`.

### Recipe → children relationships

| Relationship | Type | Delete rule |
|---|---|---|
| Recipe → ingredients | one-to-many | Cascade |
| Recipe → steps | one-to-many | Cascade |
| Recipe → spices | one-to-many | Cascade |

---

## 5. Swift Enums (`Models/Enums.swift`)

```swift
enum MealCategory: String, CaseIterable {
    case breakfast, lunch, dinner, snack, dessert   // v1
    case noodles, curry, salad, soup, ceremonial    // v2
}

enum Difficulty: String, CaseIterable {
    case easy, medium, hard
}

enum IngredientUnit: String, CaseIterable {
    case cup, tbsp, tsp
    case grams = "g", oz, ml
    case piece, pinch, none
}

enum GroceryState: String, CaseIterable {
    case needed, bought   // 2 states — haveAtHome removed in v2
}

enum SpiceCategory: String, CaseIterable {
    case driedSpices, freshHerbs, spiceBlends, heatElements, aromatics
    var displayName: String { ... }
}

enum AisleCategory: String, CaseIterable {       // v3
    case produce, dairy, meat, seafood, bakery
    case frozenFoods, pantry, beverages, household, other
    var displayName: String { ... }
    var sfSymbol: String { ... }
}

enum MealSlot: String, CaseIterable {            // v4
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
    case snack     = "snack"

    var displayName: String { rawValue.capitalized }

    var myanmarName: String {
        switch self {
        case .breakfast: return "မနက်စာ"
        case .lunch:     return "နေ့လည်စာ"
        case .dinner:    return "ညစာ"
        case .snack:     return "သရေစာ"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch:     return "sun.max"
        case .dinner:    return "moon.stars"
        case .snack:     return "leaf"
        }
    }
}

enum GroceryGenMode {                            // v4
    case merge, replace
}

enum ReplaceScope {                              // v4
    case recipeItemsOnly   // deletes GroceryItems where sourceRecipeId != nil
    case everything        // NSBatchDeleteRequest, full wipe
}
// ReplaceScope is only used when GroceryGenMode == .replace
```

---

## 6. CoreData Extensions

### Models/Recipe+Extensions.swift

```swift
var sortedIngredients: [Ingredient]
var sortedSteps: [RecipeStep]
var sortedSpices: [Spice]
var spicesByCategory: [SpiceCategory: [Spice]]
var mealCategory: MealCategory
var difficultyLevel: Difficulty
var recipeRegion: String
var titleMyanmar: String?
var descMyanmar: String?
var culturalContext: String?
var shouldUseDefaultImage: Bool
var defaultImageAssetName: String?
var customImagePath: String?
var focalPoint: CGPoint { CGPoint(x: cropFocalX, y: cropFocalY) }   // v3
```

### Models/Ingredient+Extensions.swift

```swift
var sortedSubstitutions: [IngredientSubstitution]
var hasSubstitutions: Bool
var nameMyanmar: String?
```

### Models/Spice+Extensions.swift

```swift
var spiceCategory: SpiceCategory
var displayName: String
var displayQuantity: String
```

### Models/GroceryItem+Extensions.swift

```swift
var groceryState: GroceryState
var ingredientUnit: IngredientUnit
var aisle: AisleCategory?    // v3 — nil if aisleCategory not set
```

### Models/IngredientSubstitution+Extensions.swift

```swift
var noteText: String
var contextText: String
```

### Models/MealPlanEntry+Extensions.swift *(new in v4)*

```swift
var mealSlotEnum: MealSlot {
    MealSlot(rawValue: mealSlot ?? "") ?? .dinner
}
var normalizedDate: Date {
    Calendar.current.startOfDay(for: date ?? Date())
}
var servingsCount: Int {
    Int(servings) > 0 ? Int(servings) : 1
}
```

---

## 7. Services

### Services/ScalingService.swift

Pure function, no state.

```swift
static func scale(quantity: Double, from base: Int, to target: Int) -> Double
```

Rounds to nice fractions: 0.25, 0.33, 0.5, 0.67, 0.75.

### Services/SharingService.swift

`SharedRecipePayload` Codable struct (no images).

```swift
static func encode(recipe: Recipe) -> URL?
static func decode(url: URL) -> SharedRecipePayload?
```

### Services/GroceryMergeService.swift

```swift
static func addRecipeToList(recipe: Recipe, servings: Int, context: NSManagedObjectContext)
```

- Scales each ingredient via `ScalingService`
- Merges with existing item only if **same name + same unit + same sourceRecipeId**
- Loops through `recipe.sortedSpices` after ingredients (prefixes name with `"🌶️ \(name) (\(category))"`)
- Sets `aisleCategory` via `inferAisle(from:)` on each created item
- Sets `sourceRecipeName` to `recipe.title`

### Services/ImageStore.swift

```swift
static func save(image: UIImage, id: UUID) -> String?   // returns relative path "covers/UUID.jpg"
static func load(path: String?) -> UIImage?              // handles relative + legacy absolute paths
static func delete(path: String?)                        // skips "asset:" prefixes
```

### Services/MeasurementConverter.swift

Hardcoded array of 10 `BurmeseMeasurement` entries. No CoreData. No network.

### Services/NutritionService.swift *(v3)*

```swift
static func estimate(for recipe: Recipe, servings: Int) -> NutrientSummary?
// Returns nil if fewer than 50% of ingredients matched the table.
// Result is per-serving (totals divided by servings).
```

### Services/MealPlanService.swift *(new in v4)*

```swift
struct MealPlanService {

    // All entries for Mon–Sun of the week containing `date`
    static func entries(forWeekOf date: Date, context: NSManagedObjectContext) -> [MealPlanEntry]

    // Upsert: replaces any existing entry for the same date+slot.
    // Sets entry.servings = servings parameter (default: recipe.baseServings).
    static func setEntry(recipe: Recipe, date: Date, slot: MealSlot, servings: Int, context: NSManagedObjectContext)

    // Remove a single entry
    static func removeEntry(_ entry: MealPlanEntry, context: NSManagedObjectContext)

    // Delete all MealPlanEntry rows for a given recipeId.
    // Called from commitDelete in RecipeListViewModel after undo window expires.
    static func removeAllEntries(forRecipeId id: UUID, context: NSManagedObjectContext)

    // Generate grocery list from all entries in the selected week.
    // Returns the count of newly inserted GroceryItem records.
    // mode .replace + scope .recipeItemsOnly: deletes items where sourceRecipeId != nil
    // mode .replace + scope .everything: NSBatchDeleteRequest full wipe
    // mode .merge: keeps existing, adds new items via GroceryMergeService (deduplicates by name+unit+sourceRecipeId)
    // Same recipe in two slots → two separate GroceryItem rows (one per slot, each with its own sourceRecipeId lookup pass)
    // Spices included with "🌶️" prefix, same as GroceryMergeService
    @discardableResult
    static func generateGroceryList(
        forWeekOf date: Date,
        mode: GroceryGenMode,
        replaceScope: ReplaceScope,
        context: NSManagedObjectContext
    ) -> Int
}
```

**Week date math (ISO 8601, Monday-first):**

```swift
func weekStart(for date: Date, offset: Int = 0) -> Date {
    var cal = Calendar(identifier: .iso8601)
    cal.firstWeekday = 2
    let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
    return cal.date(byAdding: .weekOfYear, value: offset, to: start)!
}
```

---

## 8. Models

### Models/NutrientSummary.swift *(v3)*

```swift
struct NutrientSummary {
    let calories: Double
    let proteinG: Double
    let carbsG:   Double
    let fatG:     Double
    let matchedCount: Int
    let totalCount: Int
    var isReliable: Bool { totalCount > 0 && Double(matchedCount) / Double(totalCount) >= 0.5 }
}
```

---

## 9. App Entry Point (`RecipeSaverApp.swift`)

- `@StateObject private var settings = SettingsStore.shared`
- Injects `managedObjectContext` + `settings` as `environmentObject`
- `onOpenURL` → `SharingService.decode` → post `.didReceiveSharedRecipe`
- `.task { seedBurmeseRecipesIfNeeded() }` — key `"hasSeededRecipesV4"`, one-time gate
- Debug mode: hash-gated reseed when `StarterRecipes.json` changes (key `starterRecipesHashV4`)
- Versioned incremental content updater reads `StarterContentUpdates.json`, tracks version in `starterContentVersionV1`
- Supports prebuilt SQLite seed bootstrap: copies `RecipeSaverSeed.sqlite` from bundle on first launch if present

### App/SettingsStore.swift

```swift
class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @Published var showBurmese: Bool        // UserDefaults key "showBurmese", default false
    @Published var mealPlanWeekWindow: Int  // UserDefaults key "mealPlanWeekWindow", default 3
    // Valid range: 1–8. Clamped on set. Never stored out of range.
}
```

### Notification names

```swift
extension Notification.Name {
    static let didReceiveSharedRecipe = Notification.Name("didReceiveSharedRecipe")
    static let recipeFeedbackEvent    = Notification.Name("recipeFeedbackEvent")
    static let navigateToRecipe       = Notification.Name("navigateToRecipe")   // v3
}

enum RecipeFeedbackAction: String { case copied, deleted, copyViewed }
```

---

## 10. Navigation Structure

```
TabView (ContentView) — 4 tabs
├── Tab 0: Recipes       (RecipeListView)       fork.knife
│   ├── RecipeDetailView
│   │   ├── CreateEditRecipeView (edit mode)
│   │   └── CookingModeView (.fullScreenCover)
│   └── CreateEditRecipeView (create mode)
├── Tab 1: Groceries     (GroceryListView)      basket
│   └── AddGroceryItemView (sheet)
├── Tab 2: Meal Plan     (MealPlanView)         calendar    ← v4
│   └── RecipePickerView (sheet, per slot)
└── Tab 3: Settings      (SettingsView)         gearshape
    └── MeasurementConverterView (sheet)

Modal (anywhere):
└── SharedRecipePreviewView (sheet, triggered by deep link)

FloatingBannerView — ZStack overlay above TabView in ContentView
```

`ContentView` holds `@State var selectedTab: Int` passed as a binding so `MealPlanView` can switch to the Groceries tab after generating a grocery list.

---

## 11. Screen Specifications

### RecipeListView

- `@FetchRequest` sorted by `createdAt` descending + `RecipeListViewModel` predicate
- Search bar, horizontal category chip scroll (All + 10 categories)
- Toggle: 2-col `LazyVGrid` (RecipeGridCard) ↔ `LazyVStack` (RecipeListCard)
- Swipe-to-delete calls `viewModel.initiateDelete(recipe:)` (3-second undo)
- Observes `.navigateToRecipe` notification to push detail on copy

### RecipeDetailView

- `RecipeHeroView` with parallax (GeometryReader, 0.5× scroll speed)
- `.ignoresSafeArea(.container, edges: .top)` on ScrollView
- Cultural note banner (terra left border)
- Title, Myanmar title, metadata pills, serving stepper
- Ingredients with scaled quantities, substitution expand button
- Spices section grouped by `SpiceCategory`
- Steps numbered list
- `DisclosureGroup` nutrition section — only shown if `NutritionService.estimate` returns non-nil; all values prefixed with `~`
- Toolbar: "Start Cooking" (flame) → `CookingModeView`
- Built-in: "Save a Copy" (shimmer on success) + Share
- User recipe: Edit + Share + Delete (3-second undo via `BannerManager`)
- "Start Shopping" → `GroceryMergeService.addRecipeToList` → switch to Groceries tab

### CreateEditRecipeView

Form sections: cover photo (PhotosPicker → `ImageCropView` fullScreenCover), title, description, category, difficulty, prep/cook/servings, ingredients (with substitutions), spices, steps. `onConfirm(UIImage, CGPoint)` captures focal point and stores to `cropFocalX`/`Y`.

### SharedRecipePreviewView

Read-only preview from deep-link payload. "Save to My Recipes" creates new CoreData recipe. No cover photo.

### GroceryListView

- Single `@FetchRequest` all items, grouped in `GroceryListViewModel`
- Sections: by `AisleCategory` (needed items), then Bought
- Tap → cycle `needed ↔ bought`; swipe to delete
- Toolbar: "Clear bought" + "+" → `AddGroceryItemView`

### AddGroceryItemView

Name (required), quantity (optional), unit picker, aisle picker (`AisleCategory?`).

### MealPlanView *(v4)*

- Title: `"Meal Plan"` (`Font.displayMd`, Newsreader italic)
- Week date range subtitle (e.g. `"Apr 21 – Apr 27"`) using `Font.bodyBold`
- `TabView(.page)` with `(mealPlanWeekWindow * 2) + 1` pages
- `weekOffset` clamped to `(-mealPlanWeekWindow)…(+mealPlanWeekWindow)`
- On appear: scroll to current week (offset 0), scroll day list to today's date
- At window boundary: soft-stop bounce — no additional pages rendered
- When `mealPlanWeekWindow` changes while view is open: clamp `weekOffset` to new boundary with animation
- Each page: `ScrollView` of 7 `MealPlanDayView` components
- Today's day header highlighted with `accentTint` background pill
- **Sticky bottom button** — "Generate Grocery List":
  - If week has **no entries**: replaced by empty state (see below)
  - Otherwise: triggers two-stage confirmation flow (see Grocery Generation section)
- Background: `Color.appBackground`; 24pt horizontal padding

**Empty state (no entries in current week):**
- Shown in place of the Generate button at the bottom of the `ScrollView`
- Icon: `calendar.badge.exclamationmark` SF symbol, `accentTint` colour
- Title: `"No meals planned"` (`Font.headlineMd`)
- Subtitle: `"Add recipes to slots to get started"` (`Font.body`, `secondaryText`)

### MealPlanDayView *(v4)*

- Header: day name (`"Monday"`) + short date (`"Apr 21"`) in `Font.bodyBold`
- Today's header: `accentTint` background pill, white text
- 4 `MealSlotCard` rows — Breakfast, Lunch, Dinner, Snack

### MealSlotCard *(v4)*

**Empty state:**
- Slot icon (`MealSlot.icon` SF symbol) + English name (`Font.bodyBold`)
- Myanmar name below if `showBurmese` (`.system()` font, `Font.bodySm`, `secondaryText`)
- Dashed border (`Color.divider`)
- Tap → `RecipePickerView` sheet

**Filled state:**
- Recipe name (`Font.bodyBold`, `primaryText`) + category chip
- Servings stepper inline: `"X servings"` / `"1 serving"` label beside `Stepper`; min 1, max 20
- Stepper change persists immediately via `PersistenceController.shared.save()`
- Long-press context menu: `"Remove"` (removes entry)
- Tap → `RecipePickerView` to replace

**Card styling:** `Color.cardFill`, `cornerRadius(12)`, subtle shadow

### RecipePickerView *(v4)*

- Sheet presentation
- Full recipe list with live search + category filter chips (same pattern as `RecipeListView`)
- Currently assigned recipe shown with `checkmark` SF symbol in `accentTint` colour
- Tapping any recipe (including current) → `viewModel.setRecipe(_:date:slot:servings:)` → dismiss
- New assignment uses `recipe.baseServings` as initial servings value
- Background: `Color.appBackground`

### CookingModeView *(v3)*

- `.fullScreenCover` from `RecipeDetailView`
- `TabView(.page)` of `CookingStepPage` views (one per step); parameter name `stepBody: String`
- `StepProgressDots` bottom centre, ✕ exit button top left
- `isIdleTimerDisabled = true` on appear, restored on disappear

### SettingsView

**Sections (in order):**
1. **Language** — `showBurmese` toggle + description
2. **Meal Plan** *(new in v4)*
   - Row label: `"Planning window"`
   - Subtitle: `"Weeks visible before and after today"` (`Font.bodySm`, `secondaryText`)
   - `Picker` with `.segmented` style, values `1…8`, labels `"1"` through `"8"`
   - Bound to `settings.mealPlanWeekWindow`
   - Persists immediately via `SettingsStore` (UserDefaults)
3. **Reference** — "Measurement Converter" row (opens sheet)
4. **About** — app name, version, recipe count

---

## 12. Grocery Generation — Full Flow *(v4)*

### Stage 1 — Mode selection (`.confirmationDialog`)

```
Title: "Generate Grocery List"
[Merge with existing list]
[Replace existing list]
[Cancel]
```

### Stage 2 — Replace only, if manually-added items detected (second `.confirmationDialog`)

Manually-added item = `sourceRecipeId == nil`

```
Title: "Your list has items you added manually"
[Replace recipe items only]   ← deletes GroceryItems where sourceRecipeId != nil
[Replace everything]          ← NSBatchDeleteRequest, full wipe
[Cancel]
```

Merge mode **skips Stage 2 entirely**.
If no manually-added items exist, Replace goes straight to generation (no Stage 2).

### After generation

1. App switches to Groceries tab (`selectedTab = 1`)
2. `FloatingBannerView` shows:
   - Title: `"Grocery list updated"`
   - Subtitle: `"X items added"` (count of newly inserted `GroceryItem` records returned by `MealPlanService.generateGroceryList`)

### Ingredient handling

- Each slot scales its ingredients by `MealPlanEntry.servings` via `ScalingService`
- Same recipe in multiple slots → **separate grocery rows per slot** (each with its own `sourceRecipeId` pass through `GroceryMergeService`)
- Spices included with `🌶️` prefix
- Aisle inference runs on each new item

---

## 13. Recipe Deletion & MealPlanEntry *(v4)*

- During 3-second undo window: `MealPlanEntry` rows are **untouched**
- After undo window expires (`onDismiss` of banner): `commitDelete` calls both:
  - `ImageStore.delete(path: recipe.coverImagePath)`
  - `MealPlanService.removeAllEntries(forRecipeId: recipe.id, context:)`
  - `context.delete(recipe)`
  - `PersistenceController.shared.save()`
- On undo: entries were never touched — nothing to restore

---

## 14. UI Components (`UI/`)

### Color+Extensions.swift — Royal Plum Adaptive Tokens

Use these in all views — never hardcode hex in view files.

| Token | Light | Dark |
|---|---|---|
| `Color.appBackground` | ivory (#fdf8f0) | darkBase (#0e0612) |
| `Color.cardFill` | ivoryDim (#f0e8dc) | darkSurface (#1a0d1e) |
| `Color.inputFill` | ivoryDim | darkElevated (#261630) |
| `Color.primaryText` | ink (#1e0d22) | plumPale (#f2e8f4) |
| `Color.secondaryText` | inkMid (#4a2d52) | plumLight (#c9a8d0) |
| `Color.tertiaryText` | inkMuted (#7a6080) | same |
| `Color.accentTint` | plumDeep (#4f055d) | plumLight (#c9a8d0) |
| `Color.divider` | plumLight @ 35% | darkBorder (#3d2445) |
| `Color.boughtFill` | #f2e8f4 | #261630 |
| `Color.foliage` | #0f6e56 | same |
| `Color.terra` | #c8794a | same |

Full raw palette and all design rules: see `DESIGN.md`.

### Font+Extensions.swift — Type Scale

| Token | Font | Size |
|---|---|---|
| `Font.displayLg` | Newsreader-Italic | 36 |
| `Font.displayMd` | Newsreader-Italic | 28 |
| `Font.headlineLg` | Newsreader-SemiBold | 22 |
| `Font.headlineMd` | Newsreader-Italic | 18 |
| `Font.serif` | Newsreader-Regular | 16 |
| `Font.labelXs` | Manrope-Bold | 9 |
| `Font.labelSm` | Manrope-SemiBold | 11 |
| `Font.body` | Manrope-Regular | 14 |
| `Font.bodySm` | Manrope-Regular | 12 |
| `Font.bodyBold` | Manrope-SemiBold | 14 |
| `Font.uiMd` | Manrope-SemiBold | 13 |
| `Font.uiSm` | Manrope-Medium | 11 |

Myanmar script always uses `.system()` font — never Newsreader or Manrope.

### AsyncRecipeImage

Crop-to-fill with focal offset. Parameters: `assetName`, `path`, `aspect` (CGFloat), `focalPoint` (CGPoint). Uses `.scaledToFill()` + `.clipped()` always. Loading state: `ShimmerView`.

### FloatingBannerView + BannerManager *(v3, replaces ToastNotification)*

```swift
BannerManager.shared.show(FloatingBanner(
    id: UUID(),
    title: "Recipe deleted",
    subtitle: "Tap Undo to restore",
    icon: "trash.fill",
    accentColor: Color.accentTint,
    actionLabel: "Undo",
    duration: 3.0,
    onAction: { /* restore */ },
    onDismiss: { /* commit delete */ }
))
```

Pill: `Color.primaryText` background, `cornerRadius(20)`, 16pt horizontal screen padding, 12pt above tab bar. Always shown in a `ZStack` overlay in `ContentView`. `BannerManager.shared` is the singleton — never instantiate a second one.

---

## 15. ViewModels

### RecipeListViewModel

```swift
@Published var searchText: String
@Published var selectedCategory: MealCategory?
@Published var isGridView: Bool
@Published var pendingDeleteID: UUID?

func predicate() -> NSPredicate?   // title CONTAINS[cd] + category + excludes pendingDeleteID
func initiateDelete(recipe:)        // sets pendingDeleteID, shows banner, on timeout calls commitDelete
// commitDelete also calls MealPlanService.removeAllEntries(forRecipeId:context:)
```

### RecipeDetailViewModel

```swift
@Published var currentServings: Int   // starts at recipe.baseServings

func scaledQuantity(for ingredient: Ingredient) -> Double
func formattedQuantity(for ingredient: Ingredient) -> String
```

### GroceryListViewModel

```swift
func toggleState(for item: GroceryItem)
func clearChecked(context: NSManagedObjectContext)   // deletes all bought items
func groupedNeededItems(from items: [GroceryItem]) -> [AisleCategory?: [GroceryItem]]
// unknown aisle (nil) placed last
```

### MealPlanViewModel *(new in v4)*

```swift
class MealPlanViewModel: ObservableObject {
    @Published var weekOffset: Int = 0
    // Observed from SettingsStore.shared via Combine or direct @ObservedObject
    var weekWindow: Int   // mirrors SettingsStore.mealPlanWeekWindow

    var currentWeekStart: Date          // weekStart(for: Date(), offset: weekOffset)
    var weekDates: [Date]               // 7 dates Mon–Sun
    var totalPages: Int { (weekWindow * 2) + 1 }

    func entry(for date: Date, slot: MealSlot) -> MealPlanEntry?
    func setRecipe(_ recipe: Recipe, date: Date, slot: MealSlot)
    // Uses recipe.baseServings as initial servings value
    func updateServings(_ servings: Int, for entry: MealPlanEntry)
    func removeEntry(_ entry: MealPlanEntry)
    func hasEntriesForCurrentWeek() -> Bool

    // Returns item count; caller shows FloatingBanner
    func generateGroceryList(mode: GroceryGenMode, replaceScope: ReplaceScope) -> Int

    // Called when weekWindow changes — clamps weekOffset if now out of range
    func clampWeekOffset()
}
```

Context is passed in on init via `@Environment(\.managedObjectContext)` — never imported as singleton in a view.

---

## 16. File Structure (v4)

```
RecipeSaver/
├── App/
│   ├── RecipeSaverApp.swift
│   └── SettingsStore.swift                      ← adds mealPlanWeekWindow in v4
├── Models/
│   ├── Enums.swift                              ← adds MealSlot, GroceryGenMode, ReplaceScope in v4
│   ├── NutrientSummary.swift
│   ├── Recipe+Extensions.swift
│   ├── Ingredient+Extensions.swift
│   ├── IngredientSubstitution+Extensions.swift
│   ├── Spice+Extensions.swift
│   ├── GroceryItem+Extensions.swift
│   ├── MealPlanEntry+Extensions.swift           ← NEW v4
│   ├── Recipe+Image.swift
│   └── Theme.swift
├── Services/
│   ├── ScalingService.swift
│   ├── SharingService.swift
│   ├── GroceryMergeService.swift
│   ├── ImageStore.swift
│   ├── MeasurementConverter.swift
│   ├── NutritionService.swift
│   └── MealPlanService.swift                    ← NEW v4
├── UI/
│   ├── Color+Extensions.swift
│   ├── Font+Extensions.swift
│   ├── AsyncRecipeImage.swift
│   ├── RecipeHeroView.swift
│   ├── RecipeListCard.swift
│   ├── ImageCropView.swift
│   ├── RecipeImageLoader.swift
│   ├── ShimmerView.swift
│   └── FloatingBannerView.swift
├── ViewModels/
│   ├── RecipeListViewModel.swift
│   ├── RecipeDetailViewModel.swift
│   ├── GroceryListViewModel.swift
│   └── MealPlanViewModel.swift                  ← NEW v4
├── Views/
│   ├── Recipes/
│   │   ├── RecipeListView.swift
│   │   ├── RecipeDetailView.swift
│   │   ├── CreateEditRecipeView.swift
│   │   └── SharedRecipePreviewView.swift
│   ├── Grocery/
│   │   ├── GroceryListView.swift
│   │   └── AddGroceryItemView.swift
│   ├── MealPlan/                                ← NEW v4
│   │   ├── MealPlanView.swift
│   │   ├── MealPlanDayView.swift
│   │   ├── MealSlotCard.swift
│   │   └── RecipePickerView.swift
│   ├── Cooking/
│   │   └── CookingModeView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── MeasurementConverterView.swift
├── Resources/
│   ├── StarterRecipes.json
│   └── StarterContentUpdates.json
├── ContentView.swift
├── Persistence.swift
├── RecipeSaver.xcdatamodeld/
│   ├── RecipeSaver.xcdatamodel                  ← v1 — do not touch
│   ├── RecipeSaver 2.xcdatamodel                ← v2 — do not touch
│   ├── RecipeSaver 3.xcdatamodel                ← v3 — do not touch
│   └── RecipeSaver 4.xcdatamodel                ← v4 — current (adds MealPlanEntry)
└── Assets.xcassets/
```

---

## 17. v4 Build Order

Each step must compile before proceeding.

1. **CoreData** — add `RecipeSaver 4.xcdatamodel` (duplicate v3, add `MealPlanEntry` entity with `servings: Integer16` field). Set as current version. Verify lightweight migration.
2. **Enums** — add `MealSlot`, `GroceryGenMode`, `ReplaceScope` to `Enums.swift`.
3. **SettingsStore** — add `mealPlanWeekWindow: Int` (`UserDefaults` key `"mealPlanWeekWindow"`, default 3, clamped 1–8).
4. **MealPlanEntry+Extensions** — `mealSlotEnum`, `normalizedDate`, `servingsCount`.
5. **MealPlanService** — implement all five static functions including `removeAllEntries(forRecipeId:context:)`. Week date math uses ISO 8601.
6. **MealPlanViewModel** — `weekOffset`, `weekDates`, `totalPages`, entry lookup, `clampWeekOffset()`, delegate mutations to service.
7. **RecipePickerView** — search + category filter sheet; checkmark on current recipe; tap → callback with `recipe.baseServings` → dismiss.
8. **MealSlotCard** — empty + filled states; inline servings stepper (min 1, max 20); long-press context menu; Myanmar slot names when `showBurmese`.
9. **MealPlanDayView** — day header (today highlighted), 4 `MealSlotCard` rows.
10. **MealPlanView** — `TabView(.page)` weekly swiper; sticky Generate button or empty state; two-stage confirmation dialog; reactive to `mealPlanWeekWindow` changes.
11. **SettingsView** — add "Meal Plan" section with segmented picker (1–8).
12. **ContentView** — add 4th tab (`MealPlanView`), expose `selectedTab` binding.
13. **Wire grocery generation** — `MealPlanService.generateGroceryList` → switch tab → `FloatingBannerView` with item count subtitle.
14. **Wire recipe deletion** — `RecipeListViewModel.commitDelete` calls `MealPlanService.removeAllEntries(forRecipeId:context:)` after undo window expires.

---

## 18. Coding Rules

### Data layer
- Never edit auto-generated CoreData files — extend only via `+Extensions.swift`
- Always call `PersistenceController.shared.save()` after any CoreData mutation
- Never pass `NSManagedObject` to service classes — map to plain Swift structs first
- Store enums as `String` rawValue in CoreData, convert at model/extension boundary
- Current CoreData version is `RecipeSaver 4.xcdatamodel` — never set an older model as current
- `MealPlanEntry` has no CoreData relationship to `Recipe` — use `recipeId` soft link + `recipeName` denormalization
- `ReplaceScope.everything` uses `NSBatchDeleteRequest` — not a loop delete

### Architecture
- Use `@FetchRequest` in views for simple static lists
- Use `ObservableObject` view models for screens with dynamic filtering or state
- Use `@StateObject` when a view owns its VM; `@ObservedObject` when passed from parent
- Use `@Environment(\.managedObjectContext)` in views — never access `PersistenceController.shared.container.viewContext` directly in a view
- `MealPlanViewModel` observes `SettingsStore.shared.mealPlanWeekWindow` — use Combine `sink` or `@ObservedObject` pattern; clamps `weekOffset` via `clampWeekOffset()` on change

### Delete flow
- Delete is never immediate — always `BannerManager` with 3-second undo; `context.delete()` only in `onDismiss`
- `ImageStore.delete()` never called before undo window expires
- `MealPlanService.removeAllEntries(forRecipeId:)` called in same `onDismiss` block as `context.delete()`

### UI
- Design language is non-negotiable — all UI must match the Royal Plum system in `DESIGN.md`
- Never hardcode hex in view files — all hex lives in `Color+Extensions.swift` only
- Text on scrim = always `Color.white` — it's on a dark gradient, not a surface
- Myanmar script = `.system()` font only — never Newsreader or Manrope
- `AsyncRecipeImage` always uses `.scaledToFill()` + `.clipped()` — never `.scaledToFit()` for recipe images
- Focal point defaults to `CGPoint(x: 0.5, y: 0.5)` — CoreData default 0.5 for both axes
- `CookingModeView` always sets `isIdleTimerDisabled = true` on appear
- `FloatingBannerView` is the only feedback UI — `ToastNotification` was removed in v3
- Banner pill background is `Color.primaryText` — no hardcoded hex
- Every screen must have a large italic serif title (`Font.displayMd` or `Font.displayLg`)
- `MealPlanView` week subtitle uses `Font.bodyBold`
- `MealSlotCard` servings label: `"1 serving"` (singular) vs `"X servings"` (plural)

### Services
- Offline-first — no network calls, no remote storage, no API integrations ever
- Nutrition estimates always show `~` prefix — never present as exact
- Nutrition section hidden if `NutritionService.estimate` returns nil
- Aisle inference runs in `GroceryMergeService` and `MealPlanService` only — `AddGroceryItemView` uses manual picker
- `GroceryState` = 2 values (`needed` / `bought`) — ignore any 3-state references in older files

### General
- No `print` statements in production paths
- Seeding key = `"hasSeededRecipesV4"`
- `BannerManager.shared` is the singleton — never instantiate a second one
- `GroceryGenMode.replace` + `ReplaceScope.everything` uses `NSBatchDeleteRequest` — not a loop
- `mealPlanWeekWindow` is always clamped to 1–8 before saving to `UserDefaults`

---

## 19. Known v3 Implementation Deviations (for reference)

| Area | Spec | Actual |
|---|---|---|
| `CookingStepPage` param | `let body: String` | `let stepBody: String` — avoids conflict with SwiftUI `var body` |
| Delete from `RecipeDetailView` | `initiateDeleteFromDetail()` | `onDeleteRequested` callback passed from `RecipeListView` — routes through `RecipeListViewModel.initiateDelete()` |
| `NutritionService.estimate` | Ambiguous | Divides all totals by servings — result is per-serving |
| `RecipeDetailView` ScrollView | Not mentioned | `.ignoresSafeArea(.container, edges: .top)` — eliminates cream gap under nav bar |
| `Font.bodyMd` | Used in spec | Does not exist — replaced with `Font.body` (Manrope-Regular 14) |
| `extension Recipe: Identifiable` | Added in list view | Removed — codegen already synthesises it; duplicate caused build error |
| `GroceryListView` bought rows | Generic surface | Uses `Color.boughtFill` token |

---

## 20. Known v4 Implementation Deviations

| Area | Spec | Actual |
|---|---|---|
| `MealPlanView` week indicator | Not specified | Sticky `weekHeader` strip pinned below nav bar: date range label + tappable bubble dots. Active week = filled `accentTint` capsule; offset-0 when inactive = `accentTint` ring outline; others = dim dots. Tapping any dot jumps to that week. |
| `MealPlanViewModel.groceryListIsEmpty()` | Not in spec | Added. `MealPlanView` generate button checks this first — if grocery list is empty, skips both dialogs and generates directly (no confirmation needed). |
| `MealSlotCard` data loading | Uses `viewModel.entry(for:slot:)` | Uses `@FetchRequest` with a custom `init` that builds an `NSFetchRequest` scoped to the specific `date+slot`. This is the reliable pattern — imperative `viewModel` fetches + `objectWillChange.send()` do not reliably drive SwiftUI re-renders for CoreData. |
| `WeekPageView` | Inline in `MealPlanView` | Extracted as a separate `struct WeekPageView: View` with its own `@FetchRequest` scoped to the week's date range (Mon–Sun). Required for `hasEntries` to react to CoreData changes without `objectWillChange`. |
| `MealPlanViewModel` entries | Drives card content | VM no longer drives card content — VM handles mutations only (`setRecipe`, `removeEntry`, `updateServings`, `generateGroceryList`, `clampWeekOffset`). Cards and the generate button read CoreData via `@FetchRequest` directly. |
| `MealPlanViewModel.groceryListIsEmpty()` implementation | N/A | Executes a synchronous `NSFetchRequest` with `fetchLimit = 1` to check existence without loading all objects. |

### Critical @FetchRequest pattern for MealSlotCard

The canonical pattern for a view needing a dynamic CoreData predicate:

```swift
struct MealSlotCard: View {
    @FetchRequest private var entries: FetchedResults<MealPlanEntry>

    init(slot: MealSlot, date: Date, viewModel: MealPlanViewModel) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let req = NSFetchRequest<MealPlanEntry>(entityName: "MealPlanEntry")
        req.predicate = NSPredicate(
            format: "date == %@ AND mealSlot == %@",
            normalizedDate as NSDate,
            slot.rawValue
        )
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntry.addedAt, ascending: false)]
        self._entries = FetchRequest(fetchRequest: req, animation: .default)
    }

    private var entry: MealPlanEntry? { entries.first }
    // ...
}
```

Do NOT use `objectWillChange.send()` + manual CoreData fetch functions as a reactivity mechanism in SwiftUI. Use `@FetchRequest` always.

---

*End of CLAUDE_v4.md — Burmese Kitchen v4*
