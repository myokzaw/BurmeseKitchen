# Burmese Kitchen — v2 Master Context for Claude Code

> **Reading order — all three files are required:**
> 1. `CLAUDE.md` — v1 architecture, CoreData setup, base services
> 2. `CLAUDE_v2.md` (this file) — v2 features, full implementation notes
> 3. `DESIGN.md` — Royal Plum color system, full-bleed scrim photo pattern, dark mode rules
>
> Do not write any UI code until all three files have been read.
> `DESIGN.md` overrides any color, typography, or photo layout decision in this file or CLAUDE.md.

---

## App Identity

**Display name:** Burmese Kitchen (set via `INFOPLIST_KEY_CFBundleDisplayName` in Build Settings — must be done in Xcode UI, not by editing `project.pbxproj` directly while Xcode is open)
**Bundle ID:** myozaw.RecipeSaver (unchanged internally)
**Target audience:** Burmese diaspora cooking at home abroad

---

## Overview of v2

v2 transforms the app from a general recipe manager into a **dedicated Burmese home cooking app for the diaspora**. Three problems solved:

1. Hard-to-find ingredients → inline substitution system
2. Informal measurements ("a tin", "a handful") → built-in converter
3. No curated Burmese recipe library → 20 hand-crafted starter recipes

**Design overhaul:**
- Royal Plum color system (deep iris purple, terracotta, ivory, full dark mode)
- Full-bleed scrim photo cards (4:3 hero, 3:2 list, 1:1 grid)
- In-app photo crop with rule-of-thirds grid

---

## v2 Feature Set

1. 20-recipe Burmese starter library with seeding
2. Ingredient substitution system (inline, expandable)
3. Informal Burmese measurement converter
4. English / Myanmar bilingual toggle
5. Royal Plum design system + full-bleed scrim photos
6. In-app photo crop (ImageCropView)
7. Spices & Seasonings section (grouped by category, scales with servings)
8. Recipe management (Copy built-in / Edit user recipe / Delete with confirmation)

---

## CoreData Schema (v2 — `RecipeSaver 2.xcdatamodel`)

### Recipe
```
id:               UUID        (required)
title:            String?
titleMy:          String?     (Myanmar script title)
desc:             String?
descMy:           String?     (Myanmar script description)
category:         String?     (breakfast|lunch|dinner|snack|dessert|noodles|curry|salad|soup|ceremonial)
region:           String?     (e.g. "Shan State", "Mandalay", "Nationwide")
difficulty:       String?     (easy|medium|hard)
prepMinutes:      Integer16   (default: 0)
cookMinutes:      Integer16   (default: 0)
baseServings:     Integer16   (default: 1)
coverImagePath:   String?     (relative path: "covers/UUID.jpg" — custom user photos)
coverImageName:   String?     (asset catalog name — built-in recipe images, e.g. "StarterMohinga")
isCustomCoverImage: Boolean   (true = user-uploaded, false = default asset)
culturalNote:     String?     (English cultural context shown in banner)
isBuiltIn:        Boolean     (true = read-only starter recipe)
createdAt:        Date?
```

**Relationships:**
- `ingredients` → Ingredient, one-to-many, cascade delete
- `steps` → RecipeStep, one-to-many, cascade delete
- `spices` → Spice, one-to-many, cascade delete

### Ingredient
```
id:        UUID
name:      String?
nameMy:    String?     (Myanmar script ingredient name)
quantity:  Double      (base quantity at recipe.baseServings)
unit:      String?
sortOrder: Integer16
```

**Relationships:**
- `recipe` → Recipe, many-to-one inverse, nullify
- `substitutions` → IngredientSubstitution, one-to-many, cascade delete

### IngredientSubstitution (new in v2)
```
id:        UUID
note:      String?     (substitute ingredient, e.g. "Tinned mackerel or sardines")
context:   String?     (when to use, e.g. "If catfish is unavailable abroad")
sortOrder: Integer16
```

**Relationships:** `ingredient` → Ingredient, many-to-one inverse, nullify

### Spice (new in v2)
```
id:        UUID
name:      String?
quantity:  Double      (base quantity at recipe.baseServings)
unit:      String?     (uses IngredientUnit rawValues)
category:  String?     (driedSpices|freshHerbs|spiceBlends|heatElements|aromatics)
sortOrder: Integer16
```

**Relationships:** `recipe` → Recipe, many-to-one inverse, nullify

### RecipeStep (unchanged)
```
id:        UUID
body:      String?
sortOrder: Integer16
```

### GroceryItem (2-state in v2)
```
id:             UUID
name:           String?
quantity:       Double?
unit:           String?
state:          String?     (needed|bought) ← haveAtHome REMOVED in v2
sourceRecipeId: UUID?       (soft link, no CoreData relationship)
sourceRecipeName: String?   (recipe title, for display reference)
addedAt:        Date?
```

---

## Intentional Deviations from CLAUDE.md

- **GroceryState has 2 states only** (`needed` / `bought`). `haveAtHome` was removed. Toggle cycles `needed → bought → needed`. "Clear checked" removes `bought` items only. Ignore any 3-state references in CLAUDE.md.
- **GroceryItem has `sourceRecipeName`** — not in CLAUDE.md schema but present in the xcdatamodeld.

---

## Enums (`Models/Enums.swift`)

```swift
enum MealCategory: String, CaseIterable {
    case breakfast, lunch, dinner, snack, dessert  // v1
    case noodles, curry, salad, soup, ceremonial   // v2
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
    case needed, bought  // 2 states only
}

enum SpiceCategory: String, CaseIterable {
    case driedSpices, freshHerbs, spiceBlends, heatElements, aromatics
    var displayName: String { ... }  // "Dried Spices", "Fresh Herbs", etc.
}
```

---

## CoreData Extensions

### Recipe+Extensions.swift
```swift
var sortedIngredients: [Ingredient]
var sortedSteps: [RecipeStep]
var sortedSpices: [Spice]
var spicesByCategory: [SpiceCategory: [Spice]]
var mealCategory: MealCategory       // rawValue parse, defaults .dinner
var difficultyLevel: Difficulty      // rawValue parse, defaults .easy
var recipeRegion: String             // region ?? "Nationwide"
var titleMyanmar: String?            // titleMy if not empty
var descMyanmar: String?             // descMy if not empty
var culturalContext: String?         // culturalNote if not empty
var shouldUseDefaultImage: Bool      // true if built-in and coverImageName set
var defaultImageAssetName: String?   // coverImageName if shouldUseDefaultImage
var customImagePath: String?         // coverImagePath if custom
```

### Ingredient+Extensions.swift
```swift
var sortedSubstitutions: [IngredientSubstitution]
var hasSubstitutions: Bool
var nameMyanmar: String?             // nameMy if not empty
```

### Spice+Extensions.swift
```swift
var spiceCategory: SpiceCategory     // rawValue parse, defaults .driedSpices
var displayName: String              // name ?? "Unknown Spice"
var displayQuantity: String          // "X unit" or "to taste" if 0
```

### GroceryItem+Extensions.swift
```swift
var groceryState: GroceryState       // rawValue parse, defaults .needed
var ingredientUnit: IngredientUnit   // rawValue parse, defaults .none
```

### IngredientSubstitution+Extensions.swift
```swift
var noteText: String                 // note ?? ""
var contextText: String              // context ?? ""
```

---

## Services

### ScalingService (`Services/ScalingService.swift`)
Pure function. No state.

```swift
static func scale(quantity: Double, from base: Int, to target: Int) -> Double
```

Rounds to nice fractions: 0.25, 0.33, 0.5, 0.67, 0.75. Snaps whole numbers.

### SharingService (`Services/SharingService.swift`)
`SharedRecipePayload` Codable struct — no images, no cover photo.
- `encode(recipe:) -> URL?` — JSON → base64 → `recipesaver://share?data=BASE64`
- `decode(url:) -> SharedRecipePayload?` — reverse

### GroceryMergeService (`Services/GroceryMergeService.swift`)
`addRecipeToList(recipe:servings:context:)`
- Scales each ingredient via ScalingService
- Merges with existing item only if **same name + same unit + same sourceRecipeId** (prevents cross-recipe merges)
- Loops through `recipe.sortedSpices` after ingredients — prefixes name with `"🌶️ \(spice.name) (\(category))"`, same merge logic
- Sets `sourceRecipeName` to `recipe.title`

### ImageStore (`Services/ImageStore.swift`)
- **Save:** `save(image:id:) -> String?` — JPEG 0.8 quality, returns **relative path** `"covers/UUID.jpg"` (stable across iOS container UUID changes)
- **Load:** `load(path:) -> UIImage?` — handles relative paths, legacy absolute paths, and `"asset:"` prefixes
- **Delete:** `delete(path:)` — skips `"asset:"` prefixed entries

### MeasurementConverter (`Services/MeasurementConverter.swift`)
Hardcoded `[BurmeseMeasurement]` array — 10 entries. No CoreData.

| Informal | Myanmar | Standard |
|---|---|---|
| 1 tin (condensed milk) | တစ်ဗူး | 397g |
| 1 coffee cup | တစ်ခွက် | 150ml |
| 1 rice bowl | တစ်ဇွန်း | 250ml |
| 1 handful (greens) | တစ်ဆုပ် | 30g |
| 1 handful (rice) | တစ်ဆုပ် | 60g |
| 1 tablespoon (Burmese) | တစ်ဇွန်း | 15ml |
| 1 viss | တစ်ဝိစ် | 1632g |
| 1 pyi | တစ်ပြည် | 1040g |
| Pinch | တစ်နယ် | 0.5 tsp |
| 1 coconut milk tin | — | 400ml |

---

## PersistenceController (`Persistence.swift`)

Lightweight migration enabled. On init, calls `migrateHaveAtHomeItems()` — converts legacy `"haveAtHome"` state items to `"needed"` (safe no-op if none exist).

---

## Seeding (`RecipeSaverApp.swift`)

Key: `"hasSeededRecipesV4"` — allows future recipe library expansion by bumping the version number.

On first launch:
1. Deletes all existing `isBuiltIn == true` recipes
2. Loads `StarterRecipes.json`
3. Decodes into `[V2StarterRecipe]` using private Codable structs (V2StarterRecipe, V2Ingredient, V2Substitution, V2Step)
4. Creates CoreData objects for each recipe + ingredients + substitutions + steps
5. Sets `coverImageName` from JSON (asset catalog name, no prefix added — must match `.imageset` folder exactly)

**20 built-in recipes** in `Resources/StarterRecipes.json`:

| Title | Myanmar | Category | Region |
|---|---|---|---|
| Mohinga | မုန့်ဟင်းခါး | soup | Nationwide |
| Shan Noodles | ရှမ်းခေါက်ဆွဲ | noodles | Shan State |
| Burmese Fish Curry | ငါးဟင်း | curry | Nationwide |
| Laphet Thoke | လက်ဖက်သုပ် | salad | Nationwide |
| Ohn No Khao Swè | အုန်းနို့ခေါက်ဆွဲ | noodles | Mandalay |
| Mont Lin Ma Yar | မုန့်လင်းမယား | snack | Nationwide |
| Shwe Gyi Sanwin Makin | ရွှေကြည်ဆနွင်းမကင်း | dessert | Nationwide |
| Spicy Chicken Fried Rice | ကြက်သားဆီထမင်း | dinner | Nationwide |
| Nan Gyi Thoke | နန်းကြီးသုပ် | noodles | Nationwide |
| Tohu Thoke | တိုဟူးသုပ် | salad | Shan State |
| Burmese Tofu | ရှမ်းတိုဟူး | snack | Shan State |
| Htamin Jin | ထမင်းချဉ် | salad | Shan State |
| Vegetarian Mohinga | သက်သတ်လွတ် မုန့်ဟင်းခါး | soup | Nationwide |
| Chicken Curry with Potatoes | ကြက်သားအာလူးဟင်း | curry | Nationwide |
| Burmese Chicken Soup | ကြက်သားဟင်းချို | soup | Nationwide |
| Moh Let Saung | မုန့်လက်ဆောင်း | dessert | Nationwide |
| Banana Fritters | ငှက်ပျောကြော် | snack | Nationwide |
| Fried Tofu with Tamarind Sauce | ကြော်တိုဟူးနှင့် ပိန္နဲရည်ဆော့စ် | snack | Shan State |
| Samosa Salad | ဆာမိုဆာသုပ် | salad | Nationwide |
| Bean Curry with Rice | ပဲဟင်း | curry | Nationwide |

---

## App Structure

### App entry (`App/RecipeSaverApp.swift`)
- `@StateObject private var settings = SettingsStore.shared`
- Injects `managedObjectContext` + `settings` as environmentObject
- `onOpenURL` → `SharingService.decode` → post `.didReceiveSharedRecipe`
- `.task { seedBurmeseRecipesIfNeeded() }`
- Declares `Notification.Name` extensions and `RecipeFeedbackAction` enum

### SettingsStore (`App/SettingsStore.swift`)
```swift
class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @Published var showBurmese: Bool  // persisted in UserDefaults key "showBurmese"
}
```

### ContentView.swift
- 3-tab TabView with `accentTint` color
  - Tab 0: RecipeListView — `fork.knife`
  - Tab 1: GroceryListView — `basket`
  - Tab 2: SettingsView — `gearshape`
- Listens for `.didReceiveSharedRecipe`, shows `SharedRecipePreviewView` as sheet

---

## UI Components (`UI/`)

### Color+Extensions.swift — Royal Plum Tokens

**Raw palette (only for use inside Color+Extensions.swift):**
| Name | Hex | Usage |
|---|---|---|
| plumDeep | #4f055d | Primary CTAs, nav active |
| plumMid | #7a2d8a | Placeholder tints |
| plumLight | #c9a8d0 | Dividers, dark mode accent |
| plumPale | #f2e8f4 | Chip backgrounds |
| terra | #c8794a | Substitutions, region badges |
| terraMid | #e8956a | Lighter terracotta |
| terraPale | #fdf0e8 | Substitution panel bg |
| ivory | #fdf8f0 | Page background (light) |
| ivoryDim | #f0e8dc | Cards, inputs (light) |
| ivoryDeep | #e0d4c4 | Deep card bg |
| foliage | #0f6e56 | Quantities, "needed" accent |
| foliagePale | #d4ede6 | Foliage tint backgrounds |
| ink | #1e0d22 | Primary text (light) |
| inkMid | #4a2d52 | Secondary text (light) |
| inkMuted | #7a6080 | Tertiary text (light) |
| darkBase | #0e0612 | Page background (dark) |
| darkSurface | #1a0d1e | Cards (dark) |
| darkElevated | #261630 | Inputs (dark) |
| darkBorder | #3d2445 | Borders (dark) |

**Adaptive tokens (use these in all views — never hardcode hex):**
| Token | Light | Dark |
|---|---|---|
| `Color.appBackground` | ivory | darkBase |
| `Color.cardFill` | ivoryDim | darkSurface |
| `Color.inputFill` | ivoryDim | darkElevated |
| `Color.primaryText` | ink | #f2e8f4 |
| `Color.secondaryText` | inkMid | #c9a8d0 |
| `Color.tertiaryText` | inkMuted | #7a6080 |
| `Color.accentTint` | plumDeep | plumLight |
| `Color.divider` | plumLight.opacity(0.35) | darkBorder |
| `Color.boughtFill` | #f2e8f4 | #261630 |
| `Color.scrimBg` | ivoryDim | darkSurface |

`Color.adaptive(light:dark:)` helper available for one-off tokens.

### Font+Extensions.swift — Type Scale

All use `Font.custom(_:size:relativeTo:)` to prevent SwiftUI weight descriptor warnings.

| Token | Font | Size | relativeTo |
|---|---|---|---|
| `Font.displayLg` | Newsreader-Italic | 36 | .largeTitle |
| `Font.displayMd` | Newsreader-Italic | 28 | .title |
| `Font.headlineLg` | Newsreader-SemiBold | 22 | .title2 |
| `Font.headlineMd` | Newsreader-Italic | 18 | .title3 |
| `Font.serif` | Newsreader-Regular | 16 | .body |
| `Font.labelXs` | Manrope-Bold | 9 | .caption2 |
| `Font.labelSm` | Manrope-SemiBold | 11 | .caption |
| `Font.body` | Manrope-Regular | 14 | .body |
| `Font.bodySm` | Manrope-Regular | 12 | .footnote |
| `Font.bodyBold` | Manrope-SemiBold | 14 | .callout |
| `Font.uiMd` | Manrope-SemiBold | 13 | .callout |
| `Font.uiSm` | Manrope-Medium | 11 | .caption |

Myanmar script always uses `.system()` — never Newsreader or Manrope.

### AsyncRecipeImage.swift
Off-thread image loader (`Task.detached`, userInitiated priority).
- `assetName` → `UIImage(named: assetName)` — must be exact asset catalog name (e.g. `"StarterMohinga"`)
- `path` → `ImageStore.load(path:)` — for custom user photos
- Never adds any prefix to `assetName` — the JSON stores the full asset name

### RecipeHeroView.swift
Full-bleed 4:3 hero with dark scrim gradient. White text overlay (always white — on dark scrim, not adaptive). Shows category, title, Myanmar title (if `showBurmese`), cook time badge, difficulty badge.

### RecipeListCard.swift
3:2 scrim card for list view. Shows Myanmar title (list only, not grid), English title, region badge (terra capsule), cook time. cornerRadius: 16.

### RecipeGridCard.swift
1:1 square card for grid view. No Myanmar script. Shows category, English title (max 2 lines), cook time. cornerRadius: 16.

### ImageCropView.swift
Full-screen cover, dark mode enforced (`.preferredColorScheme(.dark)`).
- `CropAspect` enum: `.hero` (4:3), `.card` (3:2), `.square` (1:1)
- `RuleOfThirdsGrid` visual overlay
- MagnificationGesture (1.0–4.0x) + DragGesture (clamped offset)
- Output: 1200px wide, JPEG 0.8 quality
- "Done" button (terra background) triggers `onConfirm(croppedImage)`

### ShimmerView.swift
Animated shimmer overlay. 45° gradient, 0.6s repeat, `.screen` blend mode. Applied via `.withShimmer()` modifier — used on "Save a Copy" button success state.

### ToastNotification.swift
Bottom-anchored card. Parameters: title, message, icon (SF symbol), accent color. Auto-dismisses after 2.4s with spring-in / easeInOut-out transition.

### RecipeImageLoader.swift
Static helpers: `image(for coverImageName:) -> Image`, `uiImage(for coverImageName:) -> UIImage?`. Fallback to SF symbol if asset not found.

---

## ViewModels

### RecipeListViewModel
`@Published`: `searchText`, `selectedCategory: MealCategory?`, `isGridView: Bool`
`predicate() -> NSPredicate?` — compound predicate: title CONTAINS[cd] + category ==

### RecipeDetailViewModel
`@Published`: `currentServings: Int` (starts at recipe.baseServings)
`scaledQuantity(for ingredient:) -> Double` — via ScalingService
`formattedQuantity(for ingredient:) -> String`

### GroceryListViewModel
`toggleState(for item:)` — cycles needed ↔ bought
`clearChecked(context:)` — deletes all `state == "bought"` items

---

## Views

### RecipeListView
- `@FetchRequest` sorted by `createdAt` descending + `RecipeListViewModel` predicate
- Search bar, horizontal category chip scroll (All + 10 categories)
- Toggle: 2-col `LazyVGrid` (RecipeGridCard) ↔ `LazyVStack` (RecipeListCard)
- Toolbar: grid/list toggle, + button
- Feedback banner (spring in, 2.4s auto-hide) via `.recipeFeedbackEvent` notification

### RecipeDetailView
- `RecipeHeroView` (full-bleed, no corner radius)
- Cultural note banner (terra left border) if `culturalContext` not nil
- Title + Myanmar title (if `showBurmese`)
- Metadata pills: prep, cook, difficulty, region
- Serving stepper (±1, min 1)
- Ingredients: scaled quantities (foliage), substitution expand button (terra) → expandable panel
- Myanmar ingredient names (if `showBurmese`)
- Spices section grouped by `SpiceCategory`
- Steps numbered list
- Action bar: "Start Shopping" (plumDeep) + "Converter" (terra, opens `MeasurementConverterView`)
- Toolbar (built-in): "Save a Copy" (idle/copying/success with shimmer) + Share
- Toolbar (user recipe): Edit (pencil) + Share
- Toast for copy/delete feedback

### CreateEditRecipeView
Multi-section form:
1. Cover photo picker (PhotosPicker → ImageCropView fullScreenCover → coverImage state)
2. Title (required), Description
3. Category + Difficulty pickers (HStack)
4. Prep / Cook / Base Servings steppers
5. Ingredients section — name + quantity + unit + delete; substitution rows (note + context + delete); "Add substitution" per ingredient
6. Spices section — name + quantity + unit + category picker + delete
7. Steps section — multiline text + delete
8. Save button (disabled if title empty); Delete button (user recipes only, red, confirmationDialog)

**Image crop flow:**
1. `PhotosPickerItem.onChange` loads `Data`
2. Sets `rawImage` + shows `ImageCropView` as `.fullScreenCover`
3. `onConfirm(croppedImage)` updates `coverImage` + `refreshToken`

**`loadExistingRecipe()`** on appear — loads cover image using:
- Custom path: `ImageStore.load(path: coverImagePath)`
- Built-in asset: `UIImage(named: "Starter\(assetName)")` ← note: edit view adds "Starter" prefix when loading from asset, unlike AsyncRecipeImage which stores the full name in coverImageName

**`saveRecipe()`:**
- Reuses Recipe if edit mode, creates new if create mode
- Deletes + recreates all ingredients/steps/spices (simplest approach)
- Saves cropped image via `ImageStore.save()` if image changed

**`deleteRecipe()`:**
1. `ImageStore.delete(path: recipe.coverImagePath)`
2. `context.delete(recipe)` — cascade removes ingredients/steps/spices
3. `PersistenceController.shared.save()`
4. Posts `.recipeFeedbackEvent` with `.deleted`

### SharedRecipePreviewView
Read-only preview from deep link payload. No cover photo. "Save to My Recipes" creates new CoreData Recipe + ingredients + steps, posts `.recipeFeedbackEvent` with `.copied`.

### GroceryListView
Two `@FetchRequest` properties (not in-memory filter):
- `neededItems` — `state == "needed"`, sorted by addedAt
- `boughtItems` — `state == "bought"`, sorted by addedAt

`GroceryRowView`: checkbox (plumDeep when checked), name (strikethrough if bought), quantity+unit (foliage if needed, tertiaryText if bought), `boughtFill` background if bought. Swipe to delete.

Toolbar: "Clear bought" (terra, removes all bought items) + "+" (AddGroceryItemView sheet).

### AddGroceryItemView
Name (required), optional quantity + unit picker. Creates `GroceryItem` with `state = "needed"`.

### SettingsView
Sections:
- **Language**: `showBurmese` Toggle + description
- **Reference**: "Measurement Converter" row (opens sheet)
- **About**: App name, version, recipe count

### MeasurementConverterView
Search-filtered list of `burmeseMeasurements`. Each row: informal name (with Myanmar script if `showBurmese`) → standard value (foliage) + unit + notes.

---

## Copy Built-in Recipe Flow

`saveBuiltInCopy()` in RecipeDetailView:
1. New `Recipe` with `UUID()`, `createdAt = now`, `isBuiltIn = false`
2. Title: `"\(original.title) (My Copy)"`
3. Deep copy: all metadata, ingredients (with substitutions), steps, spices
4. `coverImageName` copied as-is (built-in asset name)
5. `PersistenceController.shared.save()`
6. Shows shimmer on button + toast: "Saved!" (foliage color)
7. Posts `.recipeFeedbackEvent` with `.copied`

---

## Image System

### Built-in recipe images
Asset catalog images in `Assets.xcassets`. Naming: `Starter<RecipeName>.imageset` (e.g. `StarterMohinga.imageset`).

`coverImageName` in CoreData stores the full asset name (e.g. `"StarterMohinga"`).
`AsyncRecipeImage` calls `UIImage(named: assetName)` — no prefix added.
`CreateEditRecipeView.loadExistingRecipe()` calls `UIImage(named: "Starter\(coverImageName)")` — adds prefix for the edit form display (legacy pattern, separate from AsyncRecipeImage).

### Custom user photos
Stored as relative paths (`"covers/UUID.jpg"`) in `Documents/covers/`. `ImageStore` handles path resolution including legacy absolute paths.

---

## Notification Names

```swift
extension Notification.Name {
    static let didReceiveSharedRecipe = Notification.Name("didReceiveSharedRecipe")
    static let recipeFeedbackEvent = Notification.Name("recipeFeedbackEvent")
}

enum RecipeFeedbackAction: String {
    case copied
    case deleted
}
```

---

## File Structure (current)

```
RecipeSaver/
├── App/
│   ├── RecipeSaverApp.swift           ← @main, seeding (hasSeededRecipesV4), notifications
│   └── SettingsStore.swift
├── Models/
│   ├── Enums.swift
│   ├── Recipe+Extensions.swift
│   ├── Ingredient+Extensions.swift
│   ├── IngredientSubstitution+Extensions.swift
│   ├── Spice+Extensions.swift
│   ├── GroceryItem+Extensions.swift
│   ├── Recipe+Image.swift
│   └── Theme.swift                    ← v1 Iris Garden (unused in v2 views, kept for reference)
├── Services/
│   ├── ScalingService.swift
│   ├── SharingService.swift
│   ├── GroceryMergeService.swift
│   ├── ImageStore.swift
│   └── MeasurementConverter.swift
├── UI/
│   ├── Color+Extensions.swift
│   ├── Font+Extensions.swift
│   ├── AsyncRecipeImage.swift
│   ├── RecipeHeroView.swift
│   ├── RecipeListCard.swift
│   ├── ImageCropView.swift
│   ├── RecipeImageLoader.swift
│   ├── ShimmerView.swift
│   └── ToastNotification.swift
├── ViewModels/
│   ├── RecipeListViewModel.swift
│   ├── RecipeDetailViewModel.swift
│   └── GroceryListViewModel.swift
├── Views/
│   ├── Recipes/
│   │   ├── RecipeListView.swift
│   │   ├── RecipeDetailView.swift
│   │   ├── CreateEditRecipeView.swift
│   │   └── SharedRecipePreviewView.swift
│   ├── Grocery/
│   │   ├── GroceryListView.swift
│   │   └── AddGroceryItemView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── MeasurementConverterView.swift
├── Resources/
│   └── StarterRecipes.json            ← 20 Burmese recipes
├── ContentView.swift
├── Persistence.swift
├── RecipeSaver.xcdatamodeld/
│   ├── RecipeSaver.xcdatamodel        ← v1 schema
│   └── RecipeSaver 2.xcdatamodel      ← v2 schema (current)
└── Assets.xcassets/                   ← 20 StarterXxx.imageset images
```

---

## v2 Coding Rules (additions to CLAUDE.md §16)

- **Never use `foregroundColor`** — always `foregroundStyle` with an adaptive token
- **Never hardcode hex in views** — all hex lives in `Color+Extensions.swift` only
- **Text on scrim = always `Color.white`** — it's on a dark gradient, not a surface
- **Text on surfaces = `Color.primaryText` / `.secondaryText` / `.tertiaryText`**
- **Myanmar script = `.system()` font only** — never Newsreader or Manrope
- **`ImageCropView` = `.fullScreenCover` + `.preferredColorScheme(.dark)` always**
- **No Myanmar script in grid view** — list cards and detail screen only
- **Spice quantities always via `ScalingService`** — never hardcode
- **`AsyncRecipeImage.assetName` = full asset name** (e.g. `"StarterMohinga"`) — no prefix added
- **GroceryState = 2 values only** — ignore any 3-state references in CLAUDE.md
- **Seeding key = `"hasSeededRecipesV4"`** — bump version to reseed
- **Grocery merge = same recipe only** — GroceryMergeService checks `sourceRecipeId`

---

*End of CLAUDE_v2.md — Burmese Kitchen v2*
