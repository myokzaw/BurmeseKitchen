# Burmese Kitchen — v2 Master Context for Claude Code

> **Reading order — all three files are required:**
> 1. `CLAUDE.md` — v1 architecture, CoreData setup, base services
> 2. `CLAUDE_v2.md` (this file) — v2 features, Burmese recipes, new schema, implementation notes
> 3. `DESIGN.md` — Royal Plum color system, full-bleed scrim photo pattern, dark mode rules, crop UI
>
> Do not write any UI code until all three files have been read.
> `DESIGN.md` overrides any color, typography, or photo layout decision in this file or CLAUDE.md.

---

## App Identity

**Display name:** Burmese Kitchen (set via `INFOPLIST_KEY_CFBundleDisplayName` in Build Settings)
**Bundle ID:** myozaw.RecipeSaver (unchanged internally)
**Target audience:** Burmese diaspora cooking at home abroad

---

## Overview of v2

RecipeSaver v2 transforms the app from a general recipe manager into a **dedicated Burmese home cooking app for the diaspora**. The core insight: Burmese people living abroad deeply want to cook food from home but face three specific problems:

1. Hard-to-find ingredients with no substitution guidance
2. Traditional recipes use informal measurements ("a handful", "grandma's cup") — not standard cups/tbsp
3. No curated library of authentic Burmese recipes in one place

v2 solves all three with 4 focused features built on top of the v1 foundation.

**v2 also ships two design upgrades — see `DESIGN.md` for full specifications:**
- **Royal Plum color system** — replaces the v1 yellow-cream Iris Garden palette with deep iris purple, warm terracotta, and ivory surfaces, all with full dark mode adaptive tokens
- **Full-bleed scrim photo integration** — food photography fills cards edge-to-edge with a cinematic dark gradient anchoring text; includes in-app photo crop with rule-of-thirds grid

---

## v2 Feature Set

### Feature 1 — Burmese Recipe Library (built-in content expansion)
### Feature 2 — Ingredient Substitution System
### Feature 3 — Informal Measurement Converter
### Feature 4 — Bilingual Toggle (English / Myanmar script)
### Feature 5 — Royal Plum Design System + Full-Bleed Photo Integration (see `DESIGN.md`)
### Feature 6 — In-App Photo Crop (see `DESIGN.md` § 5 for full implementation)
### Feature 7 — Spices & Seasonings (organized by category, scales with serving size)
### Feature 8 — Recipe Management (Copy, Edit, Delete with confirmation dialogs)

---

## Feature 1: Burmese Recipe Library

### What it is
Replace the v1 generic starter recipes with a curated library of authentic Burmese home recipes. These are read-only built-in recipes (same `isBuiltIn = true` flag as v1) covering all three meal types: everyday, street food/snacks, and celebratory dishes.

### New CoreData attribute
Add one attribute to the existing `Recipe` entity:

```
region: String    // e.g. "Yangon", "Shan State", "Mandalay", "Nationwide"
```

Add to `Recipe+Extensions.swift`:
```swift
var recipeRegion: String {
    region ?? "Nationwide"
}
```

### New category values
Extend `MealCategory` enum with Burmese-specific categories:

```swift
enum MealCategory: String, CaseIterable {
    // v1 categories kept:
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case dessert = "dessert"
    // v2 Burmese-specific:
    case noodles = "noodles"         // Shan noodles, mohinga, etc.
    case curry = "curry"             // Fish curry, chicken curry
    case salad = "salad"             // Laphet thoke, thoke dishes
    case soup = "soup"               // Mohinga, hin dishes
    case ceremonial = "ceremonial"   // Festival and celebration dishes
}
```

### Starter recipe library — full content

Seed all of the following into CoreData on first launch via `StarterRecipes.json`. All have `isBuiltIn: true`.

---

#### 1. Mohinga (မုန့်ဟင်းခါး) — National dish
**Category:** soup | **Region:** Nationwide | **Difficulty:** hard | **Prep:** 30 min | **Cook:** 60 min | **Servings:** 4

**Cultural note:** Burma's national dish and the ultimate comfort food. Traditionally eaten for breakfast but available on every street corner at any hour. Every family has their own variation passed down from mother to daughter.

**Ingredients:**
- 400g catfish fillets (or substitute: tinned mackerel, sardines, or any white fish)
- 2 stalks lemongrass, bruised
- 1 tsp turmeric powder
- 1 large onion, roughly chopped
- 4 garlic cloves
- 1 tsp fresh ginger
- 2 dried red chillies, soaked in hot water
- 1 tsp shrimp paste
- 1 tsp paprika
- 6 tbsp oil
- 1.5 litres water
- 75g rice flour, toasted in dry pan until golden
- 3 tbsp fish sauce
- 1 tsp black pepper
- 500g rice vermicelli noodles

**Toppings (serve separately):**
- 4 hard-boiled eggs, halved
- Crispy fried shallots
- Chilli flakes
- Fresh coriander
- Lime wedges
- Fish sauce (extra)

**Steps:**
1. Simmer fish with lemongrass, turmeric, and 500ml water for 15 minutes. Remove fish, reserve broth. Flake fish discarding bones and skin.
2. Blend onion, garlic, ginger, soaked chillies, and shrimp paste to a smooth paste.
3. Heat oil in a large pot. Fry paste for 5 minutes until fragrant and darkened. Add paprika and turmeric.
4. Add flaked fish to the paste and mash gently together. Cook 2 minutes.
5. Pour in reserved fish broth plus remaining water. Bring to a simmer.
6. Mix toasted rice flour with a ladle of broth until smooth. Stir into the pot to thicken.
7. Add fish sauce and black pepper. Simmer 10 minutes. Taste and adjust seasoning — broth should be salty since noodles have no salt.
8. Cook noodles per packet and drain. Serve noodles in bowls, ladle soup over, add toppings to taste.

**Substitutions:**
- Catfish → tinned mackerel or sardines (authentic diaspora swap used for decades)
- Banana stem → add 12 small peeled shallots to the broth instead
- Shrimp paste → 1 tsp miso paste or omit entirely
- Toasted rice flour → toasted chickpea flour (besan/gram flour)

---

#### 2. Shan Noodles (ရှမ်းခေါက်ဆွဲ)
**Category:** noodles | **Region:** Shan State | **Difficulty:** medium | **Prep:** 20 min | **Cook:** 20 min | **Servings:** 4

**Cultural note:** Originally from the Shan people of Eastern Burma, this noodle dish is now loved across the whole country. The magic is in the layered toppings — garlic oil, chilli oil, and pickled vegetables added separately at the table.

---

#### 3. Burmese Fish Curry (ငါးဟင်း)
**Category:** curry | **Region:** Nationwide | **Difficulty:** easy | **Prep:** 15 min | **Cook:** 25 min | **Servings:** 2

**Cultural note:** Fish is central to Burmese cooking. This simple tomato-based curry is made in homes across the country. The turmeric marinade is what makes it distinctly Burmese — never skip it.

---

#### 4. Laphet Thoke — Tea Leaf Salad (လက်ဖက်သုပ်)
**Category:** salad | **Region:** Nationwide | **Difficulty:** medium | **Prep:** 30 min | **Cook:** 0 min | **Servings:** 4

**Cultural note:** Historically a peace offering between warring kingdoms. Today it is served at the end of every Burmese meal and at all social gatherings. It is arguably the most culturally significant dish in Myanmar.

---

#### 5. Ohn No Khao Swè — Coconut Chicken Noodle Soup (အုန်းနို့ခေါက်ဆွဲ)
**Category:** noodles | **Region:** Mandalay | **Difficulty:** medium | **Prep:** 20 min | **Cook:** 30 min | **Servings:** 4

**Cultural note:** A beloved Mandalay dish — creamy coconut milk broth with egg noodles, deeply influenced by Indian cuisine via the Mughal trade routes. Often served at special occasions and weddings.

---

#### 6. Mont Lin Ma Yar — Burmese Pancake Bites (မုန့်လင်းမယား)
**Category:** snack | **Region:** Nationwide | **Difficulty:** easy | **Prep:** 10 min | **Cook:** 20 min | **Servings:** 4

**Cultural note:** A beloved street food snack sold by vendors with cast iron pans filled with small round wells. The name means "husband and wife" — the quail egg sits like a couple in the batter. A quintessential Burmese childhood memory.

---

#### 7. Shwe Gyi Sanwin Makin — Semolina Cake (ရွှေကြည်ဆနွင်းမကင်)
**Category:** dessert | **Region:** Nationwide | **Difficulty:** easy | **Prep:** 10 min | **Cook:** 35 min | **Servings:** 8

**Cultural note:** A golden, fragrant semolina cake made for celebrations, merit-making ceremonies, and Thingyan (Water Festival). The topping of poppy seeds and sesame is the signature touch.

---

#### 8. Spicy Chicken Fried Rice (ကြက်သားဆီထမင်း)
**Category:** dinner | **Region:** Nationwide | **Difficulty:** easy | **Prep:** 10 min | **Cook:** 15 min | **Servings:** 2

**Cultural note:** Burmese fried rice is distinguished by its bold use of garlic, fish sauce, and chilli — simpler than Chinese versions but deeply satisfying as an everyday home meal.

---

### Seeding implementation (implemented)

Seeding uses a versioned UserDefaults key `"hasSeededRecipesV4"` so the library can be expanded and reseeded for existing installs. On each seed run, old built-in recipes are deleted first so fresh content replaces them.

**JSON Codable structs** (defined in `RecipeSaverApp.swift`):
- `V2StarterRecipe` — full recipe with bilingual fields
- `V2Ingredient` — with `nameMy` and nested `substitutions` array
- `V2Substitution` — note, context, sortOrder
- `V2Step` — body, sortOrder

**New Recipe CoreData attributes** (seeded from JSON):
- `coverImageName: String?` — asset catalog name (e.g. `"StarterMohinga"`) for built-in images
- `isCustomCoverImage: Bool` — false for built-in asset images, true for user-picked photos

---

## Feature 2: Ingredient Substitution System

### What it is
Each ingredient in a built-in Burmese recipe can have one or more substitutions — alternative ingredients that work when the original is unavailable abroad. Substitutions are displayed inline on the recipe detail screen.

### CoreData changes

New entity: **`IngredientSubstitution`**

```
id:           UUID
note:         String     // The substitution e.g. "tinned mackerel or sardines"
context:      String     // When to use it e.g. "If catfish is unavailable abroad"
sortOrder:    Integer16
```

Relationship to `Ingredient`:
```
Ingredient → substitutions (IngredientSubstitution)   One-to-many, Cascade
IngredientSubstitution → ingredient (Ingredient)      Many-to-one inverse, Nullify
```

Extensions in `Ingredient+Extensions.swift`:
```swift
var sortedSubstitutions: [IngredientSubstitution] {
    (substitutions as? Set<IngredientSubstitution> ?? [])
        .sorted { $0.sortOrder < $1.sortOrder }
}

var hasSubstitutions: Bool {
    !sortedSubstitutions.isEmpty
}
```

### UI behaviour
- On `RecipeDetailView`, ingredients with substitutions show a small swap icon (􀄸) next to the ingredient name
- Tapping the icon expands an inline panel showing substitution text
- Only built-in recipes have pre-populated substitutions
- User-created recipes can also have substitutions added manually in `CreateEditRecipeView`
- Substitution panel style: terracotta left border, `terraPale` background

---

## Feature 3: Informal Measurement Converter

### What it is
Burmese home cooks traditionally measure by feel — "a handful", "one tin of coconut milk", "grandma's cup". This feature lets users convert informal Burmese measurements into standard units so they can follow recipes accurately abroad.

### How it works
A dedicated sheet accessible from the `RecipeDetailView` toolbar (converter icon).

### Conversion reference table
Hardcoded in `Services/MeasurementConverter.swift`. No CoreData needed. Includes tin, coffee cup, rice bowl, handful (greens), handful (rice), Burmese tablespoon, viss, pyi, pinch, and coconut milk tin.

### UI
- `MeasurementConverterView` presented as a `.sheet` from recipe detail
- Simple list of all informal measurements with their equivalents
- Search bar to find a specific measurement quickly
- Each row shows: informal name → standard equivalent + contextual note
- Optional Myanmar script label shown next to the informal name when bilingual toggle is on

---

## Feature 4: Bilingual Toggle (English / Myanmar script)

### What it is
A toggle in Settings that shows Myanmar script translations alongside English for recipe titles, descriptions, and ingredient names on built-in recipes.

### CoreData changes

New attributes on `Recipe`:
```
titleMy: String?        // Myanmar script title
descMy: String?         // Myanmar script description
culturalNote: String?   // English cultural context (shown in banner on detail screen)
```

New attribute on `Ingredient`:
```
nameMy: String?         // Myanmar script ingredient name
```

### App-level state

`SettingsStore` is implemented in `App/SettingsStore.swift`:
```swift
class SettingsStore: ObservableObject {
    @Published var showBurmese: Bool {
        didSet { UserDefaults.standard.set(showBurmese, forKey: "showBurmese") }
    }
    init() {
        showBurmese = UserDefaults.standard.bool(forKey: "showBurmese")
    }
    static let shared = SettingsStore()
}
```

Injected at app root via `.environmentObject(settings)`.

### UI behaviour
- Toggle lives in a new **Settings tab** (third tab in the tab bar)
- When enabled, built-in recipe titles show both scripts stacked
- Myanmar text uses `.system(size: 17)` with `lineSpacing(4)` and `Color.secondaryText` — never custom fonts
- Ingredient names show Myanmar script in a smaller muted label below the English name
- If `titleMy` is nil (user-created recipes), toggle has no effect
- Never show Myanmar script in grid view cards — only on list cards and detail screen

### Myanmar script data for built-in recipes

| Recipe | Title (Myanmar) |
|---|---|
| Mohinga | မုန့်ဟင်းခါး |
| Shan Noodles | ရှမ်းခေါက်ဆွဲ |
| Burmese Fish Curry | ငါးဟင်း |
| Laphet Thoke | လက်ဖက်သုပ် |
| Ohn No Khao Swè | အုန်းနို့ခေါက်ဆွဲ |
| Mont Lin Ma Yar | မုန့်လင်းမယား |
| Shwe Gyi Sanwin Makin | ရွှေကြည်ဆနွင်းမကင်း |
| Spicy Chicken Fried Rice | ကြက်သားဆီထမင်း |

---

## Feature 7: Spices & Seasonings

### What it is
A dedicated spices section on every recipe, organized by category (Dried Spices, Fresh Herbs, Spice Blends, Heat Elements, Aromatics). Spice quantities scale with serving size adjustments, and spices are automatically added to the grocery list.

### CoreData entity: `Spice`
```
id:        UUID
name:      String        // e.g. "Turmeric powder"
quantity:  Double        // base quantity at baseServings
unit:      String        // uses IngredientUnit enum
category:  String        // driedSpices | freshHerbs | spiceBlends | heatElements | aromatics
sortOrder: Integer16
```

Relationship to `Recipe`:
```
spices: Set<Spice>   // One-to-many, cascade delete
```

### `SpiceCategory` enum (in `Enums.swift`)
```swift
enum SpiceCategory: String, CaseIterable {
    case driedSpices   = "driedSpices"
    case freshHerbs    = "freshHerbs"
    case spiceBlends   = "spiceBlends"
    case heatElements  = "heatElements"
    case aromatics     = "aromatics"
}
```

### Extensions
`Recipe+Extensions.swift` exposes `sortedSpices` and `spicesByCategory`.
`Spice+Extensions.swift` exposes `spiceCategory` computed property.

---

## Feature 8: Recipe Management (Copy, Edit, Delete)

### Built-in recipes (isBuiltIn = true)
- Toolbar shows **"Save a Copy"** button
- Tapping copies the entire recipe (UUID(), `isBuiltIn = false`), all ingredients, steps, spices
- Feedback banner appears: green icon, "Saved to My Recipes"

### User-created recipes (isBuiltIn = false)
- Toolbar shows **"Edit"** pencil icon → opens `CreateEditRecipeView` in edit mode
- Bottom of `CreateEditRecipeView` has **Delete** button (red styling)
- Confirmation dialog: `confirmationDialog` with `.destructive` role
- On deletion: cover photo deleted from disk, CoreData objects cascade-deleted, view dismisses
- Feedback banner appears: red icon, "Recipe Deleted"

### Feedback banners
`RecipeFeedbackBanner` component on `RecipeListView`. Posted via `NotificationCenter` using `.recipeFeedbackEvent` with `RecipeFeedbackAction` enum (`.copied` / `.deleted`).

---

## Design System: Royal Plum (implemented)

All color tokens live in `UI/Color+Extensions.swift`. Never hardcode hex values in views.

### Core palette
| Token | Light | Dark | Usage |
|---|---|---|---|
| `plumDeep` | `#4f055d` | — | CTAs, nav active, hero header |
| `terra` | `#c8794a` | — | Substitution panels, region badges |
| `ivory` | `#fdf8f0` | — | Page background (light) |
| `darkBase` | — | `#0e0612` | Page background (dark) |
| `ink` | `#1e0d22` | — | Primary text (light) |

### Adaptive tokens (use these in all views)
- `Color.appBackground` — page background
- `Color.cardFill` — card fills
- `Color.inputFill` — input backgrounds
- `Color.primaryText` / `.secondaryText` / `.tertiaryText`
- `Color.accentTint` — adaptive plum
- `Color.divider` — borders
- `Color.boughtFill` — grocery "bought" state

### Type scale (`UI/Font+Extensions.swift`)
All tokens use `Font.custom(_:size:relativeTo:)` to prevent SwiftUI font descriptor warnings.

| Token | Font | Size |
|---|---|---|
| `displayLg` | Newsreader-Italic | 36 |
| `displayMd` | Newsreader-Italic | 28 |
| `headlineLg` | Newsreader-SemiBold | 22 |
| `headlineMd` | Newsreader-Italic | 18 |
| `serif` | Newsreader-Regular | 16 |
| `labelXs` | Manrope-Bold | 9 |
| `labelSm` | Manrope-SemiBold | 11 |
| `body` | Manrope-Regular | 14 |
| `bodySm` | Manrope-Regular | 12 |
| `bodyBold` | Manrope-SemiBold | 14 |
| `uiMd` | Manrope-SemiBold | 13 |
| `uiSm` | Manrope-Medium | 11 |

---

## Image System (implemented)

### Asset catalog images (built-in recipes)
All built-in recipe cover images live in `Assets.xcassets` with the naming pattern `Starter<RecipeName>.imageset`. There are currently 8 Burmese recipe imagesets (previously 21 total including the old v1 starter recipes).

`Recipe` entity has two new image fields:
- `coverImageName: String?` — asset catalog name, set for built-in recipes
- `isCustomCoverImage: Bool` — true only when user picks their own photo

### `AsyncRecipeImage` (implemented)
Loads images off the main thread via `Task.detached`. Prefers asset catalog (`UIImage(named: assetName)`) over file system. The `assetName` must match the `.imageset` folder name exactly — no prefix is added in code.

```swift
// Correct: assetName = "StarterMohinga"  →  UIImage(named: "StarterMohinga")
// Bug that was fixed: old code did UIImage(named: "Starter\(assetName)") which created double prefix
```

### `ImageStore` (implemented)
Saves/loads/deletes custom user cover photos in `Documents/covers/` as JPEG files.

---

## Grocery List: 2-State Model (intentional deviation from CLAUDE.md)

**GroceryState has 2 states only** (not 3 as in CLAUDE.md §3.4 and §5):
- `needed` — still need to buy (default)
- `bought` — purchased

The `haveAtHome` case was removed by user request. Toggle cycles `needed → bought → needed`. "Clear checked" removes only `bought` items.

**`GroceryItem` also has a `sourceRecipeName` field** — not in the CLAUDE.md schema but present in the `.xcdatamodeld`.

---

## Notification Names (in `RecipeSaverApp.swift`)

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

## Current File Structure

```
RecipeSaver/
├── App/
│   ├── RecipeSaverApp.swift           ← @main, seeding (hasSeededRecipesV4), notification names
│   ├── ContentView.swift              ← TabView (Recipes, Groceries, Settings)
│   └── SettingsStore.swift            ← bilingual toggle ObservableObject
├── Models/
│   ├── Enums.swift                    ← MealCategory (10 cases), Difficulty, IngredientUnit, GroceryState (2 states), SpiceCategory
│   ├── Recipe+Extensions.swift        ← sortedIngredients, sortedSteps, sortedSpices, spicesByCategory, mealCategory, difficultyLevel, recipeRegion
│   ├── Ingredient+Extensions.swift    ← nameMy, sortedSubstitutions, hasSubstitutions
│   ├── GroceryItem+Extensions.swift   ← groceryState, ingredientUnit
│   ├── IngredientSubstitution+Extensions.swift
│   ├── Spice+Extensions.swift         ← spiceCategory
│   ├── Theme.swift                    ← v1 Iris Garden (kept for reference, not used in v2 views)
│   └── Recipe+Image.swift             ← image loading helpers
├── Services/
│   ├── SharingService.swift
│   ├── ScalingService.swift
│   ├── GroceryMergeService.swift
│   ├── ImageStore.swift
│   └── MeasurementConverter.swift     ← 10 informal Burmese measurements
├── UI/
│   ├── AsyncRecipeImage.swift         ← off-thread image loader (asset + file path)
│   ├── Color+Extensions.swift         ← Royal Plum adaptive tokens
│   ├── Font+Extensions.swift          ← Newsreader + Manrope type scale (relativeTo: form)
│   ├── RecipeHeroView.swift           ← full-bleed scrim hero (4:3)
│   ├── RecipeListCard.swift           ← list card (3:2) + grid card (1:1)
│   ├── RecipeImageLoader.swift        ← image loading coordinator
│   ├── ImageCropView.swift            ← in-app crop with rule-of-thirds grid
│   ├── ShimmerView.swift              ← loading shimmer animation
│   └── ToastNotification.swift        ← feedback toast component
├── ViewModels/
│   ├── RecipeListViewModel.swift
│   ├── RecipeDetailViewModel.swift
│   └── GroceryListViewModel.swift
├── Views/
│   ├── Recipes/
│   │   ├── RecipeListView.swift       ← full-bleed cards, category chips, feedback banners
│   │   ├── RecipeDetailView.swift     ← hero, cultural note, spices, substitutions, bilingual, copy/edit/share
│   │   ├── CreateEditRecipeView.swift ← full form, ImageCropView, substitutions, spices, delete
│   │   └── SharedRecipePreviewView.swift
│   ├── Grocery/
│   │   ├── GroceryListView.swift      ← 2-state toggle (needed/bought)
│   │   └── AddGroceryItemView.swift
│   └── Settings/
│       ├── SettingsView.swift         ← bilingual toggle, about section
│       └── MeasurementConverterView.swift
├── Resources/
│   └── StarterRecipes.json            ← 8 Burmese recipes with substitutions, Myanmar titles
└── RecipeSaver.xcdatamodeld/          ← two model versions (v1 + v2 with migration)
```

---

## CoreData Migration Note

v2 adds new attributes and new entities. Lightweight migration is enabled in `Persistence.swift`:

```swift
container.persistentStoreDescriptions.first?.setOption(
    true as NSNumber,
    forKey: NSMigratePersistentStoresAutomaticallyOption
)
container.persistentStoreDescriptions.first?.setOption(
    true as NSNumber,
    forKey: NSInferMappingModelAutomaticallyOption
)
```

Two `.xcdatamodel` versions exist:
- `RecipeSaver.xcdatamodel` — v1 schema
- `RecipeSaver 2.xcdatamodel` — v2 schema (current)

---

## v2 Coding Rules (additions to CLAUDE.md §16)

- **Never use `foregroundColor` in v2** — always use `foregroundStyle` with an adaptive token
- **Never hardcode a hex color in a view** — all hex values live in `Color+Extensions.swift` only
- **Text on scrim always uses `Color.white`** — it is on a dark gradient, never an app surface
- **Text on app surfaces always uses `Color.primaryText` / `.secondaryText` / `.tertiaryText`** — never hardcoded
- **Myanmar script always uses `.system()` font** — never Newsreader or Manrope
- **`ImageCropView` always presented as `.fullScreenCover` with `.preferredColorScheme(.dark)`**
- **Never show Myanmar script in grid view** — list cards and detail screen only
- **Spice quantities always scale via `ScalingService`** — never hardcode base quantities in views
- **Asset image names must match `.imageset` folder names exactly** — no prefix added in code
- **`AsyncRecipeImage.assetName` is the full asset name** (e.g. `"StarterMohinga"`) — do not concatenate a prefix
- **GroceryState has 2 values** (`needed` / `bought`) — ignore any 3-state references in CLAUDE.md
- **Always call `PersistenceController.shared.save()` after copy or delete** — CoreData mutations must persist
- **Seeding key is `"hasSeededRecipesV4"`** — do not use older keys

---

*End of CLAUDE_v2.md — Burmese Kitchen v2*
