# Burmese Kitchen

An offline-first iOS recipe app for the Burmese diaspora — bringing authentic home cooking to kitchens around the world.

---

## What it is

Burmese Kitchen helps people of Burmese heritage cook the food they grew up with, wherever they live. It solves three real problems:

- **Hard-to-find ingredients** — every recipe includes substitutions so you can cook without a trip to a specialist shop
- **Informal measurements** — traditional Burmese cooking uses "a tin", "a handful", "grandma's cup"; a built-in converter translates these into standard units
- **No curated library** — a hand-crafted collection of 20 authentic Burmese recipes, from Mohinga (the national dish) to Laphet Thoke (tea leaf salad)

---

## Features

### Recipe Library
20 built-in Burmese recipes across all meal types — soups, curries, noodles, salads, snacks, and desserts. All read-only, with the option to save a personal editable copy.

### Ingredient Substitutions
Each built-in recipe ingredient that may be hard to find abroad includes one or more diaspora-tested substitutions, shown inline on the recipe screen.

### Serving Size Adjuster
Scale any recipe up or down — all ingredient and spice quantities update live, snapping to nice fractions (¼, ⅓, ½, ¾).

### Grocery List
"Start shopping" on any recipe populates a grocery list at the current serving size. Duplicate ingredients with compatible units are merged automatically. Tap any item to mark it as bought. Items persist across app launches.

### Informal Measurement Converter
A reference sheet translating traditional Burmese kitchen measurements (tin, viss, pyi, coffee cup, rice bowl, handful) into standard metric and imperial equivalents.

### Bilingual Toggle
Enable Myanmar script in Settings to see recipe titles and ingredient names in both English and Myanmar script side by side.

### Recipe Creation & Editing
Create your own recipes with title, description, cover photo, ingredients, spices, and step-by-step instructions. Edit or delete your recipes at any time.

### Recipe Sharing
Share any recipe as a deep link (`recipesaver://share?data=...`). The recipient sees a full preview and can save it to their own collection — no account or server required.

---

## Tech Stack

| | |
|---|---|
| Language | Swift 5.10+ |
| UI | SwiftUI |
| Storage | CoreData (offline-first, device-only) |
| Minimum iOS | iOS 15 |
| Fonts | Newsreader (serif), Manrope (sans-serif) |
| Images | Local file system (`Documents/covers/`) + Asset catalog |
| Sharing | Custom URL scheme (`recipesaver://`) |
| Auth | None |
| Network | None — fully offline |

---

## Design

The app uses the **Royal Plum** design system — deep iris purple, warm terracotta, and ivory surfaces with full dark mode support. Food photography fills cards edge-to-edge with a cinematic scrim gradient.

Typography pairs **Newsreader** (an editorial serif) for recipe titles and headlines with **Manrope** (a geometric sans-serif) for all functional UI text. Myanmar script always uses the system font to ensure correct rendering.

---

## Project Structure

```
RecipeSaver/
├── App/                    # Entry point, ContentView (TabView), SettingsStore
├── Models/                 # Enums, CoreData extensions
├── Services/               # ScalingService, SharingService, GroceryMergeService, ImageStore, MeasurementConverter
├── UI/                     # Design system (Color, Font), AsyncRecipeImage, RecipeHeroView, RecipeListCard, ImageCropView
├── ViewModels/             # RecipeListViewModel, RecipeDetailViewModel, GroceryListViewModel
├── Views/
│   ├── Recipes/            # RecipeListView, RecipeDetailView, CreateEditRecipeView, SharedRecipePreviewView
│   ├── Grocery/            # GroceryListView, AddGroceryItemView
│   └── Settings/           # SettingsView, MeasurementConverterView
└── Resources/              # StarterRecipes.json (20 Burmese recipes)
```

---

## Recipes Included

| Recipe | Category | Region |
|---|---|---|
| Mohinga (မုန့်ဟင်းခါး) | Soup | Nationwide |
| Shan Noodles (ရှမ်းခေါက်ဆွဲ) | Noodles | Shan State |
| Burmese Fish Curry (ငါးဟင်း) | Curry | Nationwide |
| Laphet Thoke (လက်ဖက်သုပ်) | Salad | Nationwide |
| Ohn No Khao Swè (အုန်းနို့ခေါက်ဆွဲ) | Noodles | Mandalay |
| Mont Lin Ma Yar (မုန့်လင်းမယား) | Snack | Nationwide |
| Shwe Gyi Sanwin Makin (ရွှေကြည်ဆနွင်းမကင်း) | Dessert | Nationwide |
| Spicy Chicken Fried Rice (ကြက်သားဆီထမင်း) | Dinner | Nationwide |
| Nan Gyi Thoke (နန်းကြီးသုပ်) | Noodles | Nationwide |
| Tohu Thoke (တိုဟူးသုပ်) | Salad | Shan State |
| Burmese Tofu (ရှမ်းတိုဟူး) | Snack | Shan State |
| Htamin Jin (ထမင်းချဉ်) | Salad | Shan State |
| Vegetarian Mohinga (သက်သတ်လွတ် မုန့်ဟင်းခါး) | Soup | Nationwide |
| Chicken Curry with Potatoes (ကြက်သားအာလူးဟင်း) | Curry | Nationwide |
| Burmese Chicken Soup (ကြက်သားဟင်းချို) | Soup | Nationwide |
| Moh Let Saung (မုန့်လက်ဆောင်း) | Dessert | Nationwide |
| Banana Fritters (ငှက်ပျောကြော်) | Snack | Nationwide |
| Fried Tofu with Tamarind Sauce (ကြော်တိုဟူးနှင့် ပိန္နဲရည်ဆော့စ်) | Snack | Shan State |
| Samosa Salad (ဆာမိုဆာသုပ်) | Salad | Nationwide |
| Bean Curry with Rice (ပဲဟင်း) | Curry | Nationwide |

---

## Building

1. Open `RecipeSaver.xcodeproj` in Xcode
2. Select the `RecipeSaver` scheme
3. Build and run on an iOS 15+ simulator or device

No external dependencies or package manager configuration required.

---

## Context Files (for contributors)

Three context files live at the project root and describe the architecture in full:

- `CLAUDE.md` — v1 architecture, CoreData schema, base services
- `CLAUDE_v2.md` — v2 features, Burmese recipe library, Royal Plum design system, implementation notes
- `DESIGN.md` — full design specification including dark mode rules, typography, photo patterns, and component styling
