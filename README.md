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

### Grocery List with Aisle Grouping
"Start shopping" on any recipe populates a grocery list at the current serving size. Items are automatically organized by aisle category (produce, dairy, meat, pantry, etc.). Duplicate ingredients with compatible units are merged automatically. Tap an item to cycle through states: needed → have at home → bought. Items persist across app launches.

### Grocery Undo & Optimistic Delete
Delete any recipe with a 3-second undo window — no confirmation dialog required. Tap "Undo" to restore. Similarly, when copying a built-in recipe, a "View" button lets you jump straight to your new copy. Floating action banner with optional action button.

### Informal Measurement Converter
A reference sheet translating traditional Burmese kitchen measurements (tin, viss, pyi, coffee cup, rice bowl, handful) into standard metric and imperial equivalents.

### Bilingual Toggle
Enable Myanmar script in Settings to see recipe titles and ingredient names in both English and Myanmar script side by side.

### Recipe Creation & Editing
Create your own recipes with title, description, cover photo, ingredients, spices, and step-by-step instructions. Edit or delete your recipes at any time. Crop and set focal point on photos — cards will keep your chosen focus area in view.

### Recipe Sharing
Share any recipe as a deep link (`recipesaver://share?data=...`). The recipient sees a full preview and can save it to their own collection — no account or server required.

### Cooking Mode
Hands-free step-by-step cooking mode with swipeable pages. Screen stays on, typography optimized for readability, dismissible with a single tap. Perfect for following recipes while your hands are full.

### Parallax Hero Image
Recipe hero photo scrolls at 0.5× the scroll speed, creating a cinematic depth effect as you browse the details.

### Crop-to-Fill Image Rendering
Recipe photos intelligently crop to fill cards without stretching. Focal point anchoring ensures your chosen subject stays in view across all screen sizes.

### Nutrition Estimates (Offline)
Per-serving macro estimates (calories, protein, carbs, fat) based on ingredient lookup. Appears only when 50%+ of ingredients match the database. All ~-prefixed to indicate approximation.

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

| Recipe | Category | Region | Description |
|---|---|---|---|
| Mohinga (မုန့်ဟင်းခါး) | Soup | Nationwide | Burma's national dish — a rich, aromatic fish broth poured over rice vermicelli. Every family has their own treasured variation. |
| Shan Noodles (ရှမ်းခေါက်ဆွဲ) | Noodles | Shan State | Noodle dish from Shan State with layered toppings. Garlic oil, chilli, and peanuts all go in separately at the table. |
| Burmese Fish Curry (ငါးဟင်း) | Curry | Nationwide | Simple tomato-based curry with turmeric-marinated fish. Made in homes across the country from Yangon to riverside villages. |
| Laphet Thoke (လက်ဖက်သုပ်) | Salad | Nationwide | Pickled tea leaf salad served at the end of every Burmese meal. Historically a peace offering between warring kingdoms. |
| Ohn No Khao Swe (အုန်းနို့ခေါက်ဆွဲ) | Noodles | Mandalay | Mandalay specialty with curry noodles and coconut milk. Reflecting centuries of cultural exchange along trade routes. |
| Mont Lin Ma Yar (မုန့်လင်မယား) | Snack | Nationwide | Beloved street food snack sold by vendors with cast iron takoyaki-style pans. The name means 'husband and wife'. |
| Shwe Gyi Sanwin Makin (ရွှေကြည်ဆနွင်းမကင်း) | Dessert | Nationwide | Golden semolina cake made for celebrations and merit-making ceremonies. Popular during Thingyan, the Burmese New Year. |
| Spicy Chicken Fried Rice (အစပ်ကြက်သားထမင်းကြော်) | Dinner | Nationwide | Everyday home dish distinguished by bold use of fish sauce, garlic, and chilli. Made with day-old rice and whatever protein is on hand. |
| Nan Gyi Thoke (နန်းကြီးသုပ်) | Noodles | Nationwide | Beloved Burmese noodle salad eaten as a hearty breakfast. Thick rice noodles tossed with fragrant chicken curry sauce. |
| Tohu Thoke (တိုဟူးသုပ်) | Salad | Shan State | Shan tofu salad with chickpea flour-based tofu. Light but deeply satisfying with bright lime-garlic dressing. |
| Shan Tofu (ရှမ်းတိုဟူး) | Snack | Shan State | Yellow chickpea tofu foundational to Shan cuisine. Used in salads, fried as a snack, and served alongside soups. |
| Htamin Jin (ထမင်းချဉ်) | Salad | Shan State | Distinctive Intha and Shan specialty rice salad from Inle Lake region. Warm rice and potato tossed in garlic-infused oil. |
| Vegetarian Mohinga (သက်သတ်လွတ် မုန့်ဟင်းခါး) | Soup | Nationwide | Compassionate adaptation of Burma's national dish honoring Buddhist vegetarian principles. Mushrooms and lemongrass replace fish. |
| Chicken Curry with Potatoes (ကြက်သားအာလူးဟင်း) | Curry | Nationwide | Classic Burmese home curry in 'sibyan' style where oil separates and rises to the surface, indicating perfect balance. |
| Burmese Chicken Soup (ကြက်သားဟင်းချို) | Soup | Nationwide | Clear, light home-style soup served as component of traditional Burmese rice meal. A cleansing and sustaining note. |
| Mont Let Saung (မုန့်လက်ဆောင်း) | Dessert | Nationwide | Chilled dessert drink with sago pearls, coconut milk, and jaggery syrup. Beloved street stall treat during hot season. |
| Banana Fritters (ငှက်ပျောကြော်) | Snack | Nationwide | Common Myanmar street snack often sold with sweet Burmese milk tea at dawn. Coconut milk batter sets them apart. |
| Fried Tofu with Tamarind Sauce (တိုဟူးကြော်နှင့် မန်ကျည်းရည်ဆော့စ်) | Snack | Shan State | Fried tofu snacks with tamarind sauce. The contrast of crispy, golden tofu against tangy sauce expresses Shan cooking's genius. |
| Samosa Salad (ဆာမိုဆာသုပ်) | Salad | Nationwide | Popular street-food style salad reflecting Burmese snack culture and Indian influence. Breaking samosas into a salad transforms elements. |
| Bean Curry with Rice (ပဲဟင်းနှင့် ထမင်း) | Curry | Nationwide | Simple, nourishing everyday Burmese home dish. Humble ingredients elevated by patience and proper technique. |

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
- `CLAUDE_v3.md` — v3 features (crop-to-fill, parallax, Cooking Mode, aisle grouping, nutrition, floating banners), implementation notes
- `DESIGN.md` — full design specification including dark mode rules, typography, photo patterns, and component styling
