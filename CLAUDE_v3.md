# Burmese Kitchen — v3 Master Context for Claude Code

> **Reading order — all files are required:**
> 1. `CLAUDE.md` — v1 architecture, CoreData setup, base services
> 2. `CLAUDE_v2.md` — v2 features, full implementation notes
> 3. `CLAUDE_v3.md` (this file) — v3 features, implementation notes
> 4. `DESIGN.md` — Royal Plum color system, full-bleed scrim photo pattern, dark mode rules
>
> Do not write any UI code until all files have been read.
> `DESIGN.md` overrides any color, typography, or photo layout decision in any other file.

---

## Overview of v3

v3 is a **polish and power-user** release. It does not change the app's identity or CoreData foundations significantly — it makes the existing experience feel premium and adds two new high-value flows (Cooking Mode, Nutrition Estimates).

**Six problem areas addressed:**

1. Images stretch when container aspect ratio doesn't match the photo → **Crop-to-fill everywhere**
2. Hero photo doesn't feel connected to scroll → **Parallax hero**
3. User loses their focal subject when the card crops the image → **Focal point anchor**
4. No hands-free cooking experience → **Cooking Mode**
5. Grocery list has no spatial organisation → **Aisle grouping**
6. No nutritional context → **Offline macro estimates**
7. Deleting or copying a recipe gives poor, non-reversible feedback → **Floating action banner with Undo/View**

---

## v3 Feature Set

1. Crop-to-fill image rendering (AsyncRecipeImage + all card components)
2. Focal point anchor (ImageCropView + CoreData + card rendering)
3. Parallax hero on RecipeDetailView
4. Cooking Mode — full-screen swipeable step view, screen-always-on
5. Aisle grouping in GroceryListView
6. Offline nutrition estimates (NutritionService + RecipeDetailView section)
7. Floating action banner — Undo delete (3s) + View copy button

---

## CoreData Migration — `RecipeSaver 3.xcdatamodel`

Create a new model version by duplicating `RecipeSaver 2.xcdatamodel`. Enable lightweight migration — all new fields have defaults so no mapping model is required.

### Changes to `Recipe` entity

Add two new attributes:

```
cropFocalX:  Double   (default: 0.5)   — horizontal focal point, 0.0 = left, 1.0 = right
cropFocalY:  Double   (default: 0.5)   — vertical focal point, 0.0 = top, 1.0 = bottom
```

No other Recipe fields change.

### Changes to `GroceryItem` entity

Add one new attribute:

```
aisleCategory:  String?   (optional, no default)   — rawValue of AisleCategory enum
```

No other GroceryItem fields change.

### All other entities are unchanged

`Ingredient`, `IngredientSubstitution`, `Spice`, `RecipeStep` — no changes in v3.

---

## New Enums (`Models/Enums.swift` additions)

Add `AisleCategory` to the existing `Enums.swift` file. Do not remove any v2 enums.

```swift
enum AisleCategory: String, CaseIterable {
    case produce      = "produce"
    case dairy        = "dairy"
    case meat         = "meat"
    case seafood      = "seafood"
    case bakery       = "bakery"
    case frozenFoods  = "frozenFoods"
    case pantry       = "pantry"
    case beverages    = "beverages"
    case household    = "household"
    case other        = "other"

    var displayName: String {
        switch self {
        case .produce:     return "Produce"
        case .dairy:       return "Dairy & Eggs"
        case .meat:        return "Meat & Poultry"
        case .seafood:     return "Seafood"
        case .bakery:      return "Bakery"
        case .frozenFoods: return "Frozen Foods"
        case .pantry:      return "Pantry & Dry Goods"
        case .beverages:   return "Beverages"
        case .household:   return "Household"
        case .other:       return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .produce:     return "leaf"
        case .dairy:       return "drop"
        case .meat:        return "fork.knife"
        case .seafood:     return "fish"
        case .bakery:      return "birthday.cake"
        case .frozenFoods: return "snowflake"
        case .pantry:      return "cabinet"
        case .beverages:   return "cup.and.saucer"
        case .household:   return "house"
        case .other:       return "bag"
        }
    }
}
```

---

## CoreData Extensions (v3 additions)

### Recipe+Extensions.swift — add

```swift
/// Focal point as a CGPoint for use in image rendering. Both axes 0.0–1.0.
var focalPoint: CGPoint {
    CGPoint(x: cropFocalX, y: cropFocalY)
}
```

### GroceryItem+Extensions.swift — add

```swift
/// Parsed aisle category. Returns nil if unset (ungrouped items go in a catch-all section).
var aisle: AisleCategory? {
    guard let raw = aisleCategory else { return nil }
    return AisleCategory(rawValue: raw)
}
```

---

## New Models

### `Models/NutrientSummary.swift` (new file)

Plain Swift struct — never stored in CoreData.

```swift
struct NutrientSummary {
    let calories: Double
    let proteinG: Double
    let carbsG:   Double
    let fatG:     Double
    /// Number of ingredients that were successfully matched in the lookup table.
    let matchedCount: Int
    /// Total number of ingredients in the recipe.
    let totalCount: Int
    /// True if matchedCount / totalCount >= 0.5. If false, caller should not display estimates.
    var isReliable: Bool { totalCount > 0 && Double(matchedCount) / Double(totalCount) >= 0.5 }
}
```

---

## New Services

### `Services/NutritionService.swift` (new file)

Pure function. No state. No CoreData. No network. Fully offline.

**Design rules:**
- All estimates use `~` prefix in UI — never presented as exact
- Returns `nil` if `NutrientSummary.isReliable == false` — never show low-confidence data
- Unit conversion table is hardcoded — converts `IngredientUnit` values to grams for lookup
- Ingredient matching is case-insensitive `contains` against a dictionary of ~80 common Burmese kitchen ingredients
- The dictionary is a `private static let` constant — computed once, never re-allocated

**Unit-to-gram conversion table (hardcoded):**

| Unit | Multiplier to grams |
|---|---|
| g | 1.0 |
| oz | 28.35 |
| cup | 240.0 (liquid approximation) |
| tbsp | 15.0 |
| tsp | 5.0 |
| ml | 1.0 (liquid, density ≈ water) |
| piece | 100.0 (rough whole-item average) |
| pinch | 0.5 |
| none | 0 (skip from calculation) |

**Nutrient lookup dictionary — selected entries (implement all ~80):**

```swift
// Key: lowercase keyword to match against ingredient name
// Value: (caloriesPer100g, proteinG, carbsG, fatG)
private static let lookup: [String: (cal: Double, pro: Double, carb: Double, fat: Double)] = [
    // Proteins
    "chicken":      (165, 31.0, 0.0,  3.6),
    "beef":         (250, 26.0, 0.0,  17.0),
    "pork":         (242, 27.0, 0.0,  14.0),
    "fish":         (136, 20.0, 0.0,  6.0),
    "catfish":      (105, 18.0, 0.0,  2.9),
    "prawn":        (99,  24.0, 0.9,  0.3),
    "shrimp":       (99,  24.0, 0.9,  0.3),
    "egg":          (155, 13.0, 1.1,  11.0),
    "tofu":         (76,  8.0,  1.9,  4.8),
    // Carbs & grains
    "rice":         (130, 2.7,  28.0, 0.3),
    "noodle":       (138, 4.5,  25.0, 2.1),
    "flour":        (364, 10.0, 76.0, 1.0),
    "bread":        (265, 9.0,  49.0, 3.2),
    "banana":       (89,  1.1,  23.0, 0.3),
    "potato":       (77,  2.0,  17.0, 0.1),
    // Vegetables
    "onion":        (40,  1.1,  9.3,  0.1),
    "garlic":       (149, 6.4,  33.0, 0.5),
    "ginger":       (80,  1.8,  18.0, 0.8),
    "tomato":       (18,  0.9,  3.9,  0.2),
    "lemongrass":   (99,  1.8,  25.0, 0.5),
    "chilli":       (40,  2.0,  9.0,  0.4),
    "spinach":      (23,  2.9,  3.6,  0.4),
    "cabbage":      (25,  1.3,  6.0,  0.1),
    "mushroom":     (22,  3.1,  3.3,  0.3),
    // Dairy & fats
    "butter":       (717, 0.9,  0.1,  81.0),
    "oil":          (884, 0.0,  0.0,  100.0),
    "coconut milk": (230, 2.3,  6.0,  24.0),
    "milk":         (61,  3.2,  4.8,  3.3),
    "cream":        (340, 2.1,  2.8,  36.0),
    // Legumes
    "chickpea":     (164, 8.9,  27.0, 2.6),
    "lentil":       (116, 9.0,  20.0, 0.4),
    "bean":         (127, 8.7,  23.0, 0.5),
    // Condiments & spices (low-calorie, included for completeness)
    "fish sauce":   (35,  5.0,  3.6,  0.0),
    "soy sauce":    (53,  8.1,  4.9,  0.1),
    "sugar":        (387, 0.0,  100.0,0.0),
    "salt":         (0,   0.0,  0.0,  0.0),
    "turmeric":     (354, 8.0,  65.0, 10.0),
    "cumin":        (375, 18.0, 44.0, 22.0),
    "coriander":    (298, 12.0, 55.0, 18.0),
    "tamarind":     (239, 2.8,  63.0, 0.6),
    // Add remaining entries to reach ~80 total
]
```

**Public API:**

```swift
struct NutritionService {
    /// Estimates macros per serving for a recipe at the given serving count.
    /// Returns nil if fewer than 50% of ingredients matched the lookup table.
    static func estimate(for recipe: Recipe, servings: Int) -> NutrientSummary?
}
```

**Implementation notes:**
- Loop through `recipe.sortedIngredients` + `recipe.sortedSpices`
- For each item, find the first matching key using `ingredientName.lowercased().contains(key)`
- Convert quantity to grams using the unit table above, scaled to `servings` via `ScalingService`
- Accumulate totals, build `NutrientSummary`
- If `!summary.isReliable`, return `nil`

---

## Modified Services

### `Services/GroceryMergeService.swift` — aisle inference

After creating each `GroceryItem`, attempt to set `aisleCategory` using a hardcoded keyword lookup. This runs after the item is created but before `context.save()`.

```swift
private static func inferAisle(from name: String) -> AisleCategory {
    let lower = name.lowercased()
    // Produce
    if lower.contains(anyOf: ["tomato","onion","garlic","ginger","spinach",
                               "cabbage","mushroom","lemongrass","chilli",
                               "pepper","carrot","potato","pea","bean sprout",
                               "spring onion","shallot","coriander leaf","mint"]) { return .produce }
    // Meat
    if lower.contains(anyOf: ["chicken","beef","pork","lamb","duck","turkey",
                               "mince","sausage"]) { return .meat }
    // Seafood
    if lower.contains(anyOf: ["fish","prawn","shrimp","catfish","crab",
                               "squid","mackerel","sardine","anchovy"]) { return .seafood }
    // Dairy
    if lower.contains(anyOf: ["milk","butter","cream","cheese","yogurt","egg"]) { return .dairy }
    // Pantry
    if lower.contains(anyOf: ["rice","flour","noodle","oil","sugar","salt",
                               "soy sauce","fish sauce","tamarind","coconut milk",
                               "paste","powder","spice","turmeric","cumin",
                               "coriander","cardamom","star anise","bay leaf",
                               "sesame","dried","lentil","chickpea","bean"]) { return .pantry }
    // Beverages
    if lower.contains(anyOf: ["water","stock","broth","tea","juice"]) { return .beverages }
    // Bakery
    if lower.contains(anyOf: ["bread","dough","yeast","bun"]) { return .bakery }
    // Frozen
    if lower.contains(anyOf: ["frozen","ice"]) { return .frozenFoods }

    return .other
}
```

Add a `String` extension helper used only inside this file:
```swift
private extension String {
    func contains(anyOf keywords: [String]) -> Bool {
        keywords.contains { self.contains($0) }
    }
}
```

---

## Modified UI Components

### `UI/AsyncRecipeImage.swift` — crop-to-fill

**Problem being fixed:** Images currently stretch or leave empty space when the container aspect ratio doesn't match the image's native ratio. The fix is `.scaledToFill()` + `.clipped()` with an explicit frame on every usage context.

**New signature:**

```swift
struct AsyncRecipeImage: View {
    let assetName: String?      // built-in asset catalog name (full name, e.g. "StarterMohinga")
    let path: String?           // custom user photo relative path
    let aspect: CGFloat         // height = width * aspect (e.g. 3/4 for hero, 2/3 for list, 1/1 for grid)
    let focalPoint: CGPoint     // CGPoint(x: 0.5, y: 0.5) default — from recipe.focalPoint
}
```

**Rendering logic:**

```swift
// Inside the view body, after the image is loaded:
GeometryReader { geo in
    let w = geo.size.width
    let h = w * aspect

    image
        .resizable()
        .scaledToFill()
        .frame(width: w, height: h)
        .offset(x: focalOffsetX(imageSize: imageNativeSize, frameW: w, frameH: h),
                y: focalOffsetY(imageSize: imageNativeSize, frameW: w, frameH: h))
        .frame(width: w, height: h, alignment: .center) // clip anchor
        .clipped()
        .allowsHitTesting(false)
}
.frame(height: /* caller passes fixed height or derive from width */)
```

**Focal offset math:**

```swift
// How far to shift the image so the focal point lands at the frame centre.
// focalX = 0.0 means the user wants the left edge centred → shift right.
// focalX = 1.0 means the user wants the right edge centred → shift left.
private func focalOffsetX(imageSize: CGSize, frameW: CGFloat, frameH: CGFloat) -> CGFloat {
    // scaledToFill scale factor
    let scale = max(frameW / imageSize.width, frameH / imageSize.height)
    let scaledW = imageSize.width * scale
    let overflow = scaledW - frameW               // pixels outside the frame
    return -(focalPoint.x - 0.5) * overflow       // shift: positive = move right
}

private func focalOffsetY(imageSize: CGSize, frameW: CGFloat, frameH: CGFloat) -> CGFloat {
    let scale = max(frameW / imageSize.width, frameH / imageSize.height)
    let scaledH = imageSize.height * scale
    let overflow = scaledH - frameH
    return -(focalPoint.y - 0.5) * overflow
}
```

**Fallback (no image):** A `Color.cardFill` placeholder with a `fork.knife` SF symbol centred — same dimensions as the image would occupy, no stretching.

**Loading state:** Show `ShimmerView` at the correct aspect frame while the off-thread load is in progress.

**Callers must pass `focalPoint`:**
- `RecipeHeroView` → `recipe.focalPoint`, `aspect: 3/4`
- `RecipeListCard` → `recipe.focalPoint`, `aspect: 2/3`
- `RecipeGridCard` → `recipe.focalPoint`, `aspect: 1/1`

Built-in recipes use `CGPoint(x: 0.5, y: 0.5)` (CoreData default) — centred, identical to previous behaviour.

---

### `UI/ImageCropView.swift` — focal point step

After the user confirms the crop region, add a second step inside the same `fullScreenCover` — do not push a new view.

**Flow:**
1. Step 1 (existing): Pan + pinch to crop. "Next →" button (was "Done").
2. Step 2 (new): Show the cropped image at full screen. A draggable circle reticle (32pt diameter, `Color.white` with shadow) overlaid. Label: "Drag to set the focus point — cards will keep this area in view." "Done" button commits both the crop and the focal point.

**State additions inside `ImageCropView`:**
```swift
@State private var showFocalStep = false
@State private var focalPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
```

**Reticle gesture:**
```swift
// DragGesture on the step-2 view
// Map drag location to 0.0–1.0 relative to the image frame using GeometryReader
// Clamp result: x in [0.05, 0.95], y in [0.05, 0.95]
```

**`onConfirm` callback signature change:**
```swift
// v2:
var onConfirm: (UIImage) -> Void

// v3:
var onConfirm: (UIImage, CGPoint) -> Void   // image + focal point
```

Update all callers of `ImageCropView` (`CreateEditRecipeView`) to accept and store the `CGPoint`. Save it to `recipe.cropFocalX` / `recipe.cropFocalY` in `saveRecipe()`.

---

### `UI/ToastNotification.swift` — floating action banner (replace existing)

The v2 `ToastNotification` is a simple bottom card. v3 replaces it with a **floating pill banner** that supports an optional action button. The visual style is a rounded pill floating above the tab bar, matching the DoorDash / iOS Files pattern.

**New struct definition:**

```swift
struct FloatingBanner: Equatable {
    let id: UUID                     // for identity / cancellation
    let message: String              // e.g. "Recipe deleted"
    let icon: String                 // SF symbol name
    let accentColor: Color           // left icon tint
    let actionLabel: String?         // e.g. "Undo" or "View" — nil = no button
    let duration: Double             // seconds until auto-dismiss (3.0 for delete, 2.4 for copy)
    let onAction: (() -> Void)?      // called when action button tapped
    let onDismiss: (() -> Void)?     // called when banner auto-dismisses WITHOUT action

    static func == (lhs: FloatingBanner, rhs: FloatingBanner) -> Bool {
        lhs.id == rhs.id
    }
}
```

**Visual spec — the pill (matches reference screenshot style):**

The pill is a wide floating card anchored at the bottom of the screen above the tab bar. It matches the visual language of the reference: dark pill, left icon circle, two-line text block, ✕ dismiss button on the far right.

**Pill container:**
- Background: `Color.primaryText` — the Royal Plum `ink` token (#1e0d22, deep plum-black) in light mode, `#f2e8f4` (plumLight) in dark mode. Uses the existing adaptive token — no hardcoded hex.
- Corner radius: 20pt
- Horizontal padding (outer): 16pt from screen edges
- Internal padding: 14pt vertical, 16pt horizontal
- Shadow: `Color.accentTint.opacity(0.25)`, radius 20, x: 0, y: 8 — subtle plum-tinted shadow that lifts the pill off the screen in an on-brand way
- Width: `UIScreen.main.bounds.width - 32` — full-width minus 16pt each side
- Positioned: `safeAreaInset(edge: .bottom)` + 12pt bottom gap above tab bar

**Internal layout — HStack, spacing 12:**

```
[ leftIconCircle ]  [ textStack ]  [ Spacer ]  [ actionOrDismissButton ]
```

**Left icon circle:**
- Size: 44 × 44pt
- Background: `Color.appBackground.opacity(0.15)` — subtle frosted circle on the pill
- SF symbol inside: 20pt, `accentColor` (e.g. `Color.foliage` for copy success, `Color.accentTint` for delete)
- `.clipShape(Circle())`

**Text stack (VStack, alignment: .leading, spacing: 2):**
- Line 1 — `title`: `Font.bodyBold` (Manrope-SemiBold 14), `Color.appBackground` — the ivory/darkBase token, which contrasts against the `primaryText` pill background in both modes
- Line 2 — `subtitle`: `Font.bodySm` (Manrope-Regular 12), `Color.appBackground.opacity(0.65)`
- Both lines capped at 1 line max, `.lineLimit(1)`, `.truncationMode(.tail)`

**Right side:**
- If `actionLabel` is non-nil (e.g. "Undo", "View"): show a tappable `Text(actionLabel)` in `Font.bodyBold`, `accentColor`. Tap → `onAction?()` + dismiss.
- Always show an ✕ button regardless: `Image(systemName: "xmark")`, 14pt, `Color.appBackground.opacity(0.5)`. Tap → dismiss immediately (no `onDismiss` side effect — user explicitly cancelled).
- Layout: `[actionLabel (optional)] [xmark button]` — HStack spacing 12. If no action label, only the ✕ appears on the right.

**`FloatingBanner` struct — updated fields:**

```swift
struct FloatingBanner: Equatable {
    let id: UUID
    let title: String           // bold top line, e.g. "Recipe deleted"
    let subtitle: String        // dim bottom line, e.g. "Tap Undo to restore"
    let icon: String            // SF symbol for the left circle
    let accentColor: Color      // icon tint + action label colour
    let actionLabel: String?    // e.g. "Undo", "View" — nil = no action, only ✕
    let duration: Double        // seconds until auto-dismiss
    let onAction: (() -> Void)? // called if actionLabel tapped
    let onDismiss: (() -> Void)?// called only on timeout, NOT on ✕ tap

    static func == (lhs: FloatingBanner, rhs: FloatingBanner) -> Bool {
        lhs.id == rhs.id
    }
}
```

**Banner content per action:**

| Trigger | Icon | Accent | Title | Subtitle | Action |
|---|---|---|---|---|---|
| Delete | `trash.fill` | `Color.accentTint` | `""\(title)" deleted"` | `"Tap Undo to restore"` | `"Undo"` |
| Copy | `checkmark.circle.fill` | `Color.foliage` | `"Saved to My Recipes"` | `""\(title) (My Copy)"` | `"View"` |

**Animation:**
- Appear: `.move(edge: .bottom).combined(with: .opacity)` — spring, response 0.4, dampingFraction 0.75
- Dismiss: `.opacity` — easeInOut, 0.25s
- Use `withAnimation` blocks; do not use `.transition` on the banner directly to avoid SwiftUI list conflicts

**Timer mechanics:**
- On appear: start a `Task` that sleeps for `duration` seconds, then calls `dismiss()` + `onDismiss?()`
- If action tapped: cancel the Task, call `onAction?()`, dismiss immediately
- Only one banner visible at a time — new banner replaces old (cancel existing Task first)

**`BannerManager` — shared observable:**

```swift
@MainActor
class BannerManager: ObservableObject {
    static let shared = BannerManager()
    @Published var current: FloatingBanner? = nil
    private var dismissTask: Task<Void, Never>? = nil

    func show(_ banner: FloatingBanner) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = banner
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(banner.duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            banner.onDismiss?()
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            current = nil
        }
    }
}
```

**Inject into `ContentView`:**

```swift
// ContentView.swift — add to ZStack wrapping the TabView
@StateObject private var bannerManager = BannerManager.shared

var body: some View {
    ZStack(alignment: .bottom) {
        TabView { ... }
        
        if let banner = bannerManager.current {
            FloatingBannerView(banner: banner, manager: bannerManager)
                .padding(.horizontal, 16)
                .padding(.bottom, 12) // gap above tab bar safe area
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
        }
    }
    .environmentObject(bannerManager)
    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: bannerManager.current)
}
```

**`FloatingBannerView`** is a separate view struct that renders the pill from a `FloatingBanner` value. It is not a modifier.

**Rename rule:** The v2 `ToastNotification` struct/file is **replaced** by `FloatingBannerView` + `BannerManager`. Remove `ToastNotification.swift`. Update all v2 call sites.

---

## Delete Recipe — Optimistic UX with Undo (3 seconds)

This replaces the v2 `confirmationDialog` + immediate delete pattern.

### Flow

1. User triggers delete (swipe-to-delete in list, or Delete button in `CreateEditRecipeView` / `RecipeDetailView` toolbar).
2. **Immediate:** Remove the recipe from the displayed list via a local `@State var pendingDeleteID: UUID?` exclusion in `RecipeListViewModel.predicate()`. No CoreData write yet. `ImageStore.delete()` is NOT called yet.
3. **Immediate:** Navigate back to list if currently in `RecipeDetailView` (call `dismiss()`).
4. **Immediate:** Show floating banner via `BannerManager.shared.show(...)`:
   - Message: `""\(recipe.title ?? "Recipe")" deleted"`
   - Icon: `trash`
   - Accent: `Color.accentTint`
   - Action label: `"Undo"`
   - Duration: `3.0`
   - `onAction`: restore → clear `pendingDeleteID`, banner auto-hides
   - `onDismiss`: commit → call `commitDelete(recipe:)` (CoreData write + `ImageStore.delete()`)

5. **On undo:** `pendingDeleteID = nil` — recipe reappears in the list with a spring animation.
6. **On 3s timeout:** `commitDelete(recipe:)` runs:
   - `ImageStore.delete(path: recipe.coverImagePath)` 
   - `context.delete(recipe)` 
   - `PersistenceController.shared.save()`

### `RecipeListViewModel` — predicate update

```swift
// Add to @Published properties:
@Published var pendingDeleteID: UUID? = nil

// Update predicate() to exclude pending-delete recipe:
func predicate() -> NSPredicate? {
    var parts: [NSPredicate] = []
    if !searchText.isEmpty {
        parts.append(NSPredicate(format: "title CONTAINS[cd] %@", searchText))
    }
    if let cat = selectedCategory {
        parts.append(NSPredicate(format: "category == %@", cat.rawValue))
    }
    if let deleteID = pendingDeleteID {
        parts.append(NSPredicate(format: "id != %@", deleteID as CVarArg))
    }
    return parts.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: parts)
}
```

### Delete trigger locations

- **`RecipeListView`** — swipe-to-delete on list rows and grid cells. Calls `viewModel.initiateDelete(recipe:)` on the view model.
- **`RecipeDetailView`** — a delete toolbar button (user recipes only). Calls the same path. Dismisses the detail view immediately before banner appears.
- **`CreateEditRecipeView`** — existing Delete button at bottom of form. Same path. Dismisses form immediately.

### No `confirmationDialog` for single delete

The 3-second undo window replaces the confirmation dialog for single-recipe deletes. This is the Gmail / iOS Reminders / Notion pattern — faster, less interruptive, still safe. The `confirmationDialog` is only appropriate for batch destructive actions (not present in this app).

---

## Copy Recipe — Banner with "View" Button

This improves the v2 shimmer + toast copy flow.

### Flow

1. User taps "Save a Copy" on a built-in recipe in `RecipeDetailView`.
2. Shimmer effect on button (existing v2 behaviour — keep).
3. Perform the deep copy in CoreData (existing v2 `saveBuiltInCopy()` logic — unchanged).
4. Store the new recipe's `UUID` as `copiedRecipeID`.
5. Show floating banner via `BannerManager.shared.show(...)`:
   - Message: `"Saved to My Recipes"`
   - Icon: `checkmark.circle.fill`
   - Accent: `Color.foliage` (green)
   - Action label: `"View"`
   - Duration: `2.4`
   - `onAction`: navigate to the copied recipe's `RecipeDetailView`
   - `onDismiss`: nil (no side effect on timeout)

### Navigation to copied recipe

`RecipeDetailView` needs a way to push to another recipe from the banner action. Use a `@State var navigateToCopiedRecipe: Recipe?` + a hidden `NavigationLink` with a `tag`/`selection` binding, or (iOS 16+) `navigationDestination(item:)` if the minimum deployment target allows. If the app targets iOS 15, use the `tag`/`selection` pattern on the `NavigationStack`.

Since `BannerManager` is global, the `onAction` closure captures the `Recipe` object. The action fires `NotificationCenter.default.post(name: .navigateToRecipe, object: copiedRecipe)` and `RecipeListView` / the root navigation stack observes this notification to push the detail view.

Add to notification names:
```swift
extension Notification.Name {
    static let navigateToRecipe = Notification.Name("navigateToRecipe")
}
```

---

## New View: Parallax Hero — `RecipeDetailView`

The recipe hero image scrolls at 0.5× the scroll speed, creating a depth effect. Implemented with a `GeometryReader` anchored in global coordinate space inside the `ScrollView`.

**Implementation inside `RecipeDetailView`:**

```swift
ScrollView {
    // Parallax hero — must be the first child of ScrollView
    GeometryReader { geo in
        let globalOffset = geo.frame(in: .global).minY
        // When scrolling down: globalOffset > 0 → stretch image downward (rubber-band pull)
        // When scrolling up:   globalOffset < 0 → shift image upward at 0.5× speed
        let parallaxOffset = globalOffset > 0 ? -globalOffset : globalOffset * 0.5

        RecipeHeroView(recipe: recipe)
            .offset(y: parallaxOffset)
            // When pulling down, grow the frame so no gap appears at top
            .frame(
                height: heroHeight + max(0, -parallaxOffset * 2),
                alignment: .top
            )
    }
    .frame(height: heroHeight)   // heroHeight = UIScreen.main.bounds.width * (3.0/4.0)

    // ... rest of detail content
}
```

`RecipeHeroView` itself is unchanged — the parallax is applied by its container, not inside the component. This respects the single-responsibility principle.

---

## New View: `Views/Recipes/CookingModeView.swift`

Full-screen swipeable step-by-step cooking experience.

### Entry point

`RecipeDetailView` toolbar: a `"Start Cooking"` button (`flame` SF symbol, `Color.terra` tint) that presents `CookingModeView` as `.fullScreenCover`.

### Screen stays on

```swift
.onAppear  { UIApplication.shared.isIdleTimerDisabled = true  }
.onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
```

No entitlement or capability needed. Restored on any dismissal path.

### Layout

```swift
struct CookingModeView: View {
    let recipe: Recipe
    @State private var currentStep: Int = 0
    @Environment(\.dismiss) private var dismiss

    private var steps: [RecipeStep] { recipe.sortedSteps }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    CookingStepPage(
                        stepNumber: index + 1,
                        totalSteps: steps.count,
                        body: step.body ?? ""
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom progress dots — bottom centre
            VStack {
                Spacer()
                StepProgressDots(current: currentStep, total: steps.count)
                    .padding(.bottom, 32)
            }

            // Exit button — top left
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.secondaryText)
                            .padding(12)
                            .background(Color.cardFill)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear  { UIApplication.shared.isIdleTimerDisabled = true  }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .preferredColorScheme(nil) // honours system setting (unlike ImageCropView which forces dark)
    }
}
```

### `CookingStepPage`

```swift
// One full page in the TabView
struct CookingStepPage: View {
    let stepNumber: Int
    let totalSteps: Int
    let body: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            // Step number — large serif italic
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.Font.labelSm)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)
                .tracking(1.2)

            // Step body — large serif
            Text(body)
                .font(.Font.displayMd)   // Newsreader-Italic 28
                .foregroundStyle(Color.primaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Swipe hint (shown only on step 1, disappears after first swipe)
            if stepNumber == 1 && totalSteps > 1 {
                HStack {
                    Spacer()
                    Text("Swipe to continue →")
                        .font(.Font.bodySm)
                        .foregroundStyle(Color.tertiaryText)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 80) // clear progress dots
    }
}
```

### `StepProgressDots`

```swift
struct StepProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.accentTint : Color.divider)
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}
```

---

## Modified View: `Views/Grocery/GroceryListView.swift` — aisle grouping

### Data model change

Replace the two `@FetchRequest` properties (needed / bought) with a single `@FetchRequest` for all items, then group in the view model.

```swift
// GroceryListViewModel — new computed property
func groupedNeededItems(from items: [GroceryItem]) -> [(aisle: AisleCategory?, items: [GroceryItem])] {
    let needed = items.filter { $0.groceryState == .needed }
    let grouped = Dictionary(grouping: needed) { $0.aisle }
    
    // Sort: known aisles first (in AisleCategory.allCases order), then nil (ungrouped) last
    var result: [(aisle: AisleCategory?, items: [GroceryItem])] = AisleCategory.allCases
        .compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (aisle: cat, items: items.sorted { ($0.addedAt ?? .distantPast) < ($1.addedAt ?? .distantPast) })
        }

    // Items with no aisle set
    if let ungrouped = grouped[nil], !ungrouped.isEmpty {
        result.append((aisle: nil, items: ungrouped))
    }
    return result
}
```

### Section headers

Each aisle section header shows: `[SF symbol] [displayName]` in `Font.uiMd`, `Color.secondaryText`. No background — uses the standard `List` section header style.

### `AddGroceryItemView` — aisle picker

Add an optional `Picker("Aisle", selection: $selectedAisle)` using `.menu` style. Bound to `@State var selectedAisle: AisleCategory? = nil`. If nil, `aisleCategory` is not set on save (will appear in the ungrouped section). The picker shows `AisleCategory.allCases` with their `sfSymbol` + `displayName`, plus a "Don't categorise" option.

### Auto-inferred aisle on "Start Shopping"

`GroceryMergeService.addRecipeToList()` now calls `inferAisle(from: name)` for each created item and sets `item.aisleCategory`. Manually-added items have no auto-inference — the user picks via the `AddGroceryItemView` picker.

---

## Modified View: `Views/Recipes/RecipeDetailView.swift` — nutrition section

### Where it appears

A collapsible `DisclosureGroup` section below the Steps list, above the action bar. Label: `"Nutrition Estimate per Serving"`.

### Content

```swift
// Only shown if NutritionService.estimate returns non-nil
if let nutrition = NutritionService.estimate(for: recipe, servings: viewModel.currentServings) {
    DisclosureGroup("Nutrition Estimate per Serving") {
        HStack(spacing: 0) {
            NutrientPill(label: "Calories", value: "~\(Int(nutrition.calories))", unit: "kcal")
            NutrientPill(label: "Protein",  value: "~\(Int(nutrition.proteinG))", unit: "g")
            NutrientPill(label: "Carbs",    value: "~\(Int(nutrition.carbsG))",   unit: "g")
            NutrientPill(label: "Fat",      value: "~\(Int(nutrition.fatG))",     unit: "g")
        }
        Text("Estimates based on \(nutrition.matchedCount) of \(nutrition.totalCount) ingredients. Values are approximate.")
            .font(.Font.bodySm)
            .foregroundStyle(Color.tertiaryText)
            .padding(.top, 4)
    }
    .tint(Color.accentTint)
}
```

```swift
struct NutrientPill: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.Font.headlineMd)
                .foregroundStyle(Color.foliage)
            Text(unit)
                .font(.Font.labelXs)
                .foregroundStyle(Color.tertiaryText)
            Text(label)
                .font(.Font.labelSm)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
```

Nutrition **re-computes** whenever `viewModel.currentServings` changes — no caching needed since it's a pure function over a small dataset.

---

## `RecipeFeedbackAction` — updated

```swift
// RecipeSaverApp.swift — update enum
enum RecipeFeedbackAction: String {
    case copied
    case deleted
    case copyViewed   // fired when user taps "View" on the copy banner — for analytics/future use
}
```

The `.recipeFeedbackEvent` notification is still posted for compatibility, but the primary feedback UI path is now `BannerManager` directly.

---

## File Structure (v3 — changes from v2)

```
RecipeSaver/
├── App/
│   ├── RecipeSaverApp.swift           ← add navigateToRecipe notification
│   └── SettingsStore.swift            (unchanged)
├── Models/
│   ├── Enums.swift                    ← add AisleCategory
│   ├── NutrientSummary.swift          ← NEW
│   ├── Recipe+Extensions.swift        ← add focalPoint computed var
│   ├── Ingredient+Extensions.swift    (unchanged)
│   ├── IngredientSubstitution+Extensions.swift (unchanged)
│   ├── Spice+Extensions.swift         (unchanged)
│   ├── GroceryItem+Extensions.swift   ← add aisle computed var
│   ├── Recipe+Image.swift             (unchanged)
│   └── Theme.swift                    (unchanged)
├── Services/
│   ├── ScalingService.swift           (unchanged)
│   ├── SharingService.swift           (unchanged)
│   ├── GroceryMergeService.swift      ← add inferAisle, set aisleCategory on items
│   ├── ImageStore.swift               (unchanged)
│   ├── MeasurementConverter.swift     (unchanged)
│   └── NutritionService.swift         ← NEW
├── UI/
│   ├── Color+Extensions.swift         (unchanged)
│   ├── Font+Extensions.swift          (unchanged)
│   ├── AsyncRecipeImage.swift         ← crop-to-fill + focal offset + updated signature
│   ├── RecipeHeroView.swift           (unchanged — parallax applied by caller)
│   ├── RecipeListCard.swift           ← pass focalPoint to AsyncRecipeImage
│   ├── RecipeGridCard.swift           ← pass focalPoint to AsyncRecipeImage
│   ├── ImageCropView.swift            ← add focal point step 2, update onConfirm signature
│   ├── RecipeImageLoader.swift        (unchanged)
│   ├── ShimmerView.swift              (unchanged)
│   ├── ToastNotification.swift        ← REPLACED by FloatingBannerView.swift
│   └── FloatingBannerView.swift       ← NEW (replaces ToastNotification)
├── ViewModels/
│   ├── RecipeListViewModel.swift      ← add pendingDeleteID, update predicate()
│   ├── RecipeDetailViewModel.swift    (unchanged)
│   └── GroceryListViewModel.swift     ← add groupedNeededItems()
├── Views/
│   ├── Recipes/
│   │   ├── RecipeListView.swift       ← swipe-to-delete calls initiateDelete, observe navigateToRecipe
│   │   ├── RecipeDetailView.swift     ← parallax hero, cooking mode button, nutrition section, updated banner calls
│   │   ├── CreateEditRecipeView.swift ← updated onConfirm (focal point), updated delete path
│   │   └── SharedRecipePreviewView.swift (unchanged)
│   ├── Grocery/
│   │   ├── GroceryListView.swift      ← aisle-grouped sections
│   │   └── AddGroceryItemView.swift   ← aisle picker
│   ├── Cooking/
│   │   └── CookingModeView.swift      ← NEW (includes CookingStepPage, StepProgressDots)
│   └── Settings/
│       ├── SettingsView.swift         (unchanged)
│       └── MeasurementConverterView.swift (unchanged)
├── Resources/
│   └── StarterRecipes.json            (unchanged)
├── ContentView.swift                  ← inject BannerManager, add FloatingBannerView overlay
├── Persistence.swift                  (unchanged)
├── RecipeSaver.xcdatamodeld/
│   ├── RecipeSaver.xcdatamodel        ← v1 (do not touch)
│   ├── RecipeSaver 2.xcdatamodel      ← v2 (do not touch)
│   └── RecipeSaver 3.xcdatamodel      ← NEW — cropFocalX, cropFocalY, aisleCategory
└── Assets.xcassets/                   (unchanged)
```

---

## v3 Build Order

Build in this exact order. Each step must compile before proceeding.

1. **CoreData** — add `RecipeSaver 3.xcdatamodel` with `cropFocalX`, `cropFocalY`, `aisleCategory`. Set as current model. Verify lightweight migration runs cleanly on a device with v2 data.
2. **Enums** — add `AisleCategory` to `Enums.swift`.
3. **Models** — add `NutrientSummary.swift`. Update `Recipe+Extensions` (focalPoint), `GroceryItem+Extensions` (aisle).
4. **NutritionService** — implement `NutritionService.swift` with lookup table and `estimate()` function. Write unit tests if time allows.
5. **GroceryMergeService** — add `inferAisle()` and set `aisleCategory` on new items.
6. **FloatingBannerView + BannerManager** — build and test in isolation before wiring to delete/copy. Replace `ToastNotification.swift`.
7. **ContentView** — inject `BannerManager`, add `FloatingBannerView` overlay at bottom of ZStack.
8. **AsyncRecipeImage** — implement crop-to-fill + focal offset. Test with built-in recipes (defaults to 0.5/0.5) and a custom photo.
9. **ImageCropView** — add focal point step 2 and update `onConfirm` signature. Update `CreateEditRecipeView` caller.
10. **RecipeListCard + RecipeGridCard** — pass `focalPoint` to updated `AsyncRecipeImage`.
11. **Delete flow** — update `RecipeListViewModel` with `pendingDeleteID`, wire `initiateDelete()`, update `RecipeListView` swipe-to-delete and `RecipeDetailView` delete button.
12. **Copy flow** — update `saveBuiltInCopy()` to use `BannerManager` with "View" action button. Wire `navigateToRecipe` notification.
13. **Parallax hero** — wrap `RecipeHeroView` in `GeometryReader` inside `RecipeDetailView`.
14. **CookingModeView** — build full view. Add "Start Cooking" toolbar button in `RecipeDetailView`.
15. **GroceryListView aisle grouping** — group items by aisle, render section headers. Update `AddGroceryItemView` with picker.
16. **Nutrition section** — add `DisclosureGroup` section to `RecipeDetailView`. Verify it recomputes on serving change.

---

## v3 Coding Rules (additions to v2 rules)

- **`FloatingBannerView` is the only feedback UI** — do not use `ToastNotification`. It has been removed.
- **Delete is never immediate** — always go through `BannerManager` with a 3-second undo window. `context.delete()` is only called in `onDismiss`, never inline.
- **`ImageStore.delete()` is never called before the undo window expires** — deleting the image file during the grace period would break undo.
- **`AsyncRecipeImage` always uses `scaledToFill` + `clipped`** — `.scaledToFit` is never used for recipe images in cards or the hero.
- **Focal point defaults to `CGPoint(x: 0.5, y: 0.5)`** — all CoreData defaults are 0.5, so built-in recipes are unaffected and centred.
- **`CookingModeView` always sets `isIdleTimerDisabled = true` in `onAppear`** and restores it in `onDisappear`. No exceptions.
- **Nutrition estimates always show `~` prefix** — never present as exact values in UI.
- **Nutrition section is hidden if `NutritionService.estimate` returns `nil`** — never show a section with placeholder text.
- **`BannerManager.shared` is the singleton** — never instantiate a second `BannerManager`.
- **Banner pill background is `Color.primaryText`** — the existing Royal Plum adaptive token (deep plum-black in light, near-white in dark). No hardcoded hex. No exception to the design system rules.
- **Banner text uses `Color.appBackground` / `Color.appBackground.opacity(0.65)`** — the inverse of the pill background, ensuring legibility in both light and dark mode automatically.
- **The ✕ button always appears** — even when there is an action label. ✕ dismisses immediately with no side effect (no `onDismiss` callback, no undo commit). Action label dismisses and fires `onAction`. They are independent.
- **`FloatingBanner` has `title` + `subtitle` (two lines)**, not a single `message` string. All call sites must supply both.
- **Aisle inference runs in `GroceryMergeService` only** — `AddGroceryItemView` uses a manual picker. Do not auto-infer in the manual add flow.
- **Parallax offset is applied in `RecipeDetailView`, not inside `RecipeHeroView`** — `RecipeHeroView` is a dumb display component.

---

## v3 Implementation Status

**All 16 build steps complete. Project builds cleanly with zero errors.**

### Deviations from spec

| Area | Spec | Actual |
|---|---|---|
| `CookingStepPage` param | `let body: String` | renamed to `let stepBody: String` — `body` conflicts with SwiftUI `var body: some View` |
| `RecipeDetailView` delete | Internal `initiateDeleteFromDetail()` | Replaced with `onDeleteRequested: (() -> Void)?` callback passed from `RecipeListView` — routes through `RecipeListViewModel.initiateDelete()` which properly sets `pendingDeleteID` and uses the proven list-delete path |
| `NutritionService.estimate` | "per serving" (implicit) | Explicitly divides all macro totals by `servings` before returning `NutrientSummary` — spec was ambiguous; without the division the function returned total for all servings, not per serving |
| `RecipeDetailView` ScrollView | No mention | Added `.ignoresSafeArea(.container, edges: .top)` so the parallax hero extends behind the navigation bar — eliminates the cream gap at the top |
| `Font.bodyMd` | Used in spec snippets | Does not exist in `Font+Extensions.swift` — replaced with `Font.body` (Manrope-Regular 14) at all call sites |
| `extension Recipe: Identifiable` | Added in `RecipeListView` | Removed — CoreData class-definition codegen already synthesises conformance; duplicate caused a build error |
| `GroceryListView` bought row | Generic surface styling | Uses `Color.boughtFill` (defined in `Color+Extensions.swift` as plumLight adaptive token) for subtle distinction |

### Post-spec bug fixes

1. **Nutrition per-serving**: `NutritionService.estimate(for:servings:)` was calculating macro totals for `servings` servings total, not per serving. Fixed by dividing totals by `max(servings, 1)`.

2. **Delete from RecipeDetailView not committing**: The old `initiateDeleteFromDetail()` relied on capturing `recipe` in an `onDismiss` closure after the view was dismissed, and did not set `pendingDeleteID` — so the recipe remained visible in the list during the undo window and the CoreData write path was fragile. Replaced with `onDeleteRequested` callback delegation to `RecipeListView.deleteRecipe()`.

3. **Top whitespace on RecipeDetailView**: Standard `ScrollView` safe area inset created a cream gap between the navigation bar and the hero image. Fixed with `.ignoresSafeArea(.container, edges: .top)` on the `ScrollView`.

### Files touched beyond the spec file list

- `RecipeSaver/RecipeSaverApp.swift` — added `navigateToRecipe` notification name, `copyViewed` case to `RecipeFeedbackAction`
- `RecipeSaver/ContentView.swift` — BannerManager injection + `FloatingBannerView` overlay
- `RecipeSaver/Views/Recipes/CreateEditRecipeView.swift` — updated `onConfirm` closure to accept `(UIImage, CGPoint)` for focal point; BannerManager-based delete

---

*End of CLAUDE_v3.md — Burmese Kitchen v3*
