# AGENTS.md — Burmese Kitchen

## Project overview

**Burmese Kitchen** is an offline-first iOS recipe app for the Burmese diaspora (bundle ID: `myozaw.RecipeSaver`).
It is built with SwiftUI + CoreData, targets iOS 15+, and has no backend, no auth, and no network calls of any kind.

The full spec lives in `CLAUDE_v4.md` (required reading before touching any code) and `DESIGN.md` (overrides all color/typography decisions). Read both before writing any UI code.

Current CoreData version: **`RecipeSaver 4.xcdatamodel`**. Never set an older model version as current.

---

## Dev environment

- Open `RecipeSaver.xcodeproj` in Xcode 15+.
- Build target: **RecipeSaver** (iPhone). iPad and Mac are out of scope.
- Minimum deployment target: **iOS 15**.
- No Swift Package Manager dependencies — all code is first-party.
- Custom fonts (Newsreader, Manrope) must be present in the bundle and declared in `Info.plist` under `UIAppFonts`.
- App display name is set via `INFOPLIST_KEY_CFBundleDisplayName` in Build Settings — never edit `project.pbxproj` directly while Xcode is open.

---

## Build order

When adding new features, follow this sequence — each step must compile before proceeding:

1. CoreData schema (new `.xcdatamodel` version, lightweight migration)
2. Enums (`Models/Enums.swift`)
3. CoreData `+Extensions.swift` files
4. Service files (`Services/`)
5. ViewModels (`ViewModels/`)
6. Leaf views (cards, subviews)
7. Screen views (full screens)
8. Wiring (tab navigation, notifications, bindings)

---

## Architecture rules

- **Never edit auto-generated CoreData files.** Add all logic via `+Extensions.swift` files only.
- **Always call `PersistenceController.shared.save()`** after any CoreData mutation.
- **Never pass `NSManagedObject` to service classes** — map to plain Swift structs first.
- **Store enums as `String` rawValue** in CoreData; convert at the model/extension boundary.
- Use `@FetchRequest` in views for simple static lists.
- Use `ObservableObject` ViewModels for screens with dynamic filtering or state.
- Use `@StateObject` when a view owns its VM; `@ObservedObject` when passed from a parent.
- Use `@Environment(\.managedObjectContext)` in views — never access `PersistenceController.shared.container.viewContext` directly in a view.
- `MealPlanEntry` has **no CoreData relationship** to `Recipe` — use `recipeId` soft link + `recipeName` denormalization only.

---

## Delete flow (non-negotiable)

Deletion is **never immediate**. The pattern is always:

1. Call `viewModel.initiateDelete(recipe:)` — sets `pendingDeleteID`, shows `FloatingBannerView` with 3-second timer.
2. `onAction` (Undo) — restores state, cancels timer.
3. `onDismiss` (timer expires) — `commitDelete`:
   - `ImageStore.delete(path: recipe.coverImagePath)`
   - `MealPlanService.removeAllEntries(forRecipeId: recipe.id, context:)`
   - `context.delete(recipe)`
   - `PersistenceController.shared.save()`

`ImageStore.delete()` and `MealPlanService.removeAllEntries()` must **never** be called before the undo window expires.

---

## UI rules

- **Never hardcode hex values in view files.** All hex lives exclusively in `UI/Color+Extensions.swift`.
- **Never use `foregroundColor`** — always `foregroundStyle` with an adaptive token.
- **Text on scrim = `Color.white` always** — it sits on a dark gradient, not a surface.
- **Text on surfaces = `Color.primaryText` / `.secondaryText` / `.tertiaryText`.**
- **Myanmar script = `.system()` font only** — never Newsreader or Manrope.
- **`AsyncRecipeImage` always uses `.scaledToFill()` + `.clipped()`** — never `.scaledToFit()`.
- **`ImageCropView` = `.fullScreenCover` + `.preferredColorScheme(.dark)` always.**
- **`FloatingBannerView` is the only feedback UI** — `ToastNotification` was removed in v3.
- **Every screen must have a large italic serif title** (`Font.displayMd` or `Font.displayLg`).
- Banner pill background is `Color.primaryText` — no hardcoded hex.
- No Myanmar script in grid view cards — list cards and detail screen only.

---

## Key constants

| Constant | Value |
|---|---|
| Seeding UserDefaults key | `"hasSeededRecipesV4"` |
| Content version key | `"starterContentVersionV1"` |
| Recipes hash key | `"starterRecipesHashV4"` |
| Week window UserDefaults key | `"mealPlanWeekWindow"` |
| Week window default | `3` (range: 1–8) |
| `BannerManager` singleton | `BannerManager.shared` — never instantiate a second one |
| Undo window duration | 3 seconds |
| `GroceryState` values | `needed`, `bought` only — ignore any 3-state references in older files |

---

## Meal plan specifics (v4)

- Week navigation uses **ISO 8601, Monday-first** calendar.
- Total `TabView` pages = `(mealPlanWeekWindow * 2) + 1`. `weekOffset` is clamped to `±mealPlanWeekWindow`.
- At the boundary, the swipe soft-stops (bounces back) — no additional pages are rendered.
- `MealPlanEntry.servings` defaults to `recipe.baseServings` at assignment time; range 1–20.
- Stepper changes persist immediately via `PersistenceController.shared.save()`.
- `MealPlanEntry` rows are **untouched** during the 3-second recipe undo window.
- Same recipe in multiple slots → **separate grocery rows per slot** (not merged).
- `GroceryGenMode.replace` + `ReplaceScope.everything` uses `NSBatchDeleteRequest` — never a loop.
- `MealPlanService.generateGroceryList` returns an `Int` item count; the caller shows the banner.

---

## Services: what lives where

| Responsibility | Service |
|---|---|
| Ingredient quantity scaling | `ScalingService` (pure, no state) |
| Deep-link encode/decode | `SharingService` |
| Recipe → grocery list | `GroceryMergeService` |
| Local image save/load/delete | `ImageStore` |
| Burmese measurement lookup | `MeasurementConverter` (hardcoded, no CoreData) |
| Offline nutrition estimates | `NutritionService` (~80-ingredient table, per-serving) |
| Meal plan CRUD + grocery gen | `MealPlanService` |

---

## @FetchRequest with dynamic predicates (v4 pattern)

When a view needs CoreData data scoped to a runtime value (e.g. a specific date + meal slot), use a custom `init` to build the `NSFetchRequest` and assign it to the `@FetchRequest` wrapper:

```swift
init(slot: MealSlot, date: Date) {
    let req = NSFetchRequest<MealPlanEntry>(entityName: "MealPlanEntry")
    req.predicate = NSPredicate(format: "date == %@ AND mealSlot == %@",
        Calendar.current.startOfDay(for: date) as NSDate, slot.rawValue)
    req.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntry.addedAt, ascending: false)]
    self._entries = FetchRequest(fetchRequest: req, animation: .default)
}
```

**Do not** use `viewModel.someFunction()` + `objectWillChange.send()` as a substitute. Manual imperative fetches + `objectWillChange` do not reliably trigger SwiftUI re-renders for CoreData changes. Always prefer `@FetchRequest`.

When a parent view also needs to react to CoreData changes (e.g. to show an empty state), extract it as a separate struct with its own `@FetchRequest` — do not try to pass `FetchedResults` between views.

---

## Things that must never happen

- No network calls, API integrations, or remote storage — ever.
- No `print` statements in production paths.
- No hardcoded hex in view files.
- No editing auto-generated CoreData files.
- No setting an older `.xcdatamodel` version as current.
- No `haveAtHome` grocery state — it was removed in v2.
- No `ToastNotification` — it was removed in v3.
- No `Font.bodyMd` — it does not exist; use `Font.body` (Manrope-Regular 14).
- No `extension Recipe: Identifiable` — codegen already synthesises it; duplicates cause build errors.
- No second `BannerManager` instance.
- Nutrition estimates always display a `~` prefix — never present as exact values.
