# DESIGN.md — Iris Garden · RecipeSaver v2.2

> Drop this file into the Xcode project root alongside CLAUDE.md and CLAUDE_v2.md.
> Claude Code reads all three before writing any UI code.
> This file governs every visual decision in the app. Non-negotiable.

---

## 1. Design Philosophy

**"Botanical Editorial meets Burmese Lacquerware."**

The app should feel like a beautifully printed Burmese cookbook — warm ivory pages, deep iris-purple chapter headers, warm terracotta accents that echo temple brickwork and lacquerware. Food photography is the hero. Every screen should make the user feel like they are holding something crafted, not generated.

### The anti-vibe-code rules — read these first

Most AI-generated apps look identical because they reuse the same five patterns. This app must not use any of them:

**Banned patterns — never use these:**
- Rounded rectangle with a colored left border accent (the "card with stripe" — every AI app has it)
- Capsule/pill chips with solid color fill for category filters
- Buttons with `RoundedRectangle(cornerRadius: 12)` and a flat color background
- `.overlay(alignment: .leading) { Rectangle() }` for decorative accents
- Cards that are just `Color.cardFill` rectangles with text inside — no shape, no texture, no character

**What to use instead — see Section 8 for full implementations:**
- **Substitution notes**: inline italic text directly in the ingredient row, no panel at all
- **Cultural notes**: full-width serif quote block with oversized decorative punctuation, no border
- **Category filters**: horizontally scrolling text-only tabs underlined with a single pixel, not pills
- **Primary CTA**: full-bleed bottom bar that floats above content, not a button in the scroll
- **Ingredient rows**: two-column layout with quantity right-aligned in foliage color, separated by a hairline, not a card

**Three rules that override everything else:**
1. **Photos always win.** Never let UI chrome compete with food imagery.
2. **Myanmar script is a whisper, not a shout.** It sits below English titles in a softer tone — secondary, never dominant.
3. **Dark mode is a first-class citizen.** Every color, every text element, every surface must be explicitly tested for dark mode. No hardcoded black text. Ever.

---

## 2. Color System — Royal Plum

### Primary palette

```swift
// MARK: — Royal Plum Color Tokens
// Add these to a Color+Extensions.swift file or Assets.xcassets color set

extension Color {

    // — Plum family (primary brand)
    static let plumDeep    = Color(hex: "#4f055d")  // CTAs, nav active, recipe hero header
    static let plumMid     = Color(hex: "#7a2d8a")  // Hover states, category swatch (soup)
    static let plumLight   = Color(hex: "#c9a8d0")  // Dividers, Myanmar script text (light mode)
    static let plumPale    = Color(hex: "#f2e8f4")  // Grocery "bought" state bg, active tab bg (light)

    // — Terracotta family (accent — means "adapt / help")
    static let terra       = Color(hex: "#c8794a")  // Substitution panels, Converter CTA, region badges
    static let terraMid    = Color(hex: "#e8956a")  // Terra hover state, highlight rings
    static let terraPale   = Color(hex: "#fdf0e8")  // Substitution panel background (light mode)

    // — Ivory family (surfaces)
    static let ivory       = Color(hex: "#fdf8f0")  // Page background (light mode)
    static let ivoryDim    = Color(hex: "#f0e8dc")  // Card fills, input backgrounds, inactive chips
    static let ivoryDeep   = Color(hex: "#e0d4c4")  // Pressed states, strong dividers

    // — Foliage family (kept from Iris Garden v1)
    static let foliage     = Color(hex: "#0f6e56")  // Ingredient quantities, "have at home" grocery state
    static let foliagePale = Color(hex: "#d4ede6")  // "Have at home" grocery bg, active foliage chips

    // — Ink (text)
    static let ink         = Color(hex: "#1e0d22")  // Primary text (light mode) — never pure black
    static let inkMid      = Color(hex: "#4a2d52")  // Secondary text, descriptions (light mode)
    static let inkMuted    = Color(hex: "#7a6080")  // Tertiary text, labels, timestamps (light mode)

    // — Dark mode surfaces
    static let darkBase    = Color(hex: "#0e0612")  // Page background (dark mode)
    static let darkSurface = Color(hex: "#1a0d1e")  // Card fills (dark mode)
    static let darkElevated = Color(hex: "#261630") // Input backgrounds, chips (dark mode)
    static let darkBorder  = Color(hex: "#3d2445")  // Dividers, borders (dark mode)

    // — Dark mode text
    static let darkTextPrimary   = Color(hex: "#f2e8f4")  // Primary text (dark mode)
    static let darkTextSecondary = Color(hex: "#c9a8d0")  // Secondary text (dark mode)
    static let darkTextTertiary  = Color(hex: "#7a6080")  // Tertiary text (dark mode)
}
```

### Adaptive color helper

```swift
// MARK: — Adaptive Colors (light/dark aware)
// Use these everywhere in views — never hardcode light or dark alone

extension Color {
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    // Ready-made adaptive tokens
    static let appBackground  = adaptive(light: .ivory,       dark: .darkBase)
    static let cardFill       = adaptive(light: .ivoryDim,    dark: .darkSurface)
    static let inputFill      = adaptive(light: .ivoryDim,    dark: .darkElevated)
    static let primaryText    = adaptive(light: .ink,         dark: .darkTextPrimary)
    static let secondaryText  = adaptive(light: .inkMid,      dark: .darkTextSecondary)
    static let tertiaryText   = adaptive(light: .inkMuted,    dark: .darkTextTertiary)
    static let divider        = adaptive(light: .plumLight.opacity(0.35), dark: .darkBorder)
    static let scrimBg        = adaptive(light: .ivoryDim,    dark: .darkSurface)
}
```

### Color roles by feature

| Element | Light mode | Dark mode |
|---|---|---|
| Page background | `#fdf8f0` ivory | `#0e0612` darkBase |
| Card fill | `#f0e8dc` ivoryDim | `#1a0d1e` darkSurface |
| Input / chip bg | `#f0e8dc` ivoryDim | `#261630` darkElevated |
| Primary text | `#1e0d22` ink | `#f2e8f4` plumPale |
| Secondary text | `#4a2d52` inkMid | `#c9a8d0` plumLight |
| Tertiary text | `#7a6080` inkMuted | `#7a6080` inkMuted |
| Dividers | `plumLight` 35% | `#3d2445` darkBorder |
| Primary CTA | `#4f055d` plumDeep | `#7a2d8a` plumMid |
| Accent CTA / substitution | `#c8794a` terra | `#e8956a` terraMid |
| Ingredient quantities | `#0f6e56` foliage | `#5DCAA5` foliageMid |
| Grocery: needed | `#f0e8dc` ivoryDim | `#1a0d1e` darkSurface |
| Grocery: have at home | `#d4ede6` foliagePale | `#0f3412` foliageDark |
| Grocery: bought | `#f2e8f4` plumPale | `#261630` darkElevated |
| Nav active | `#f2e8f4` + plumDeep text | `#261630` + plumLight text |

---

## 3. Typography

### Font pairing

```swift
// Headline / Display: Newsreader (serif) — storytelling, recipe titles, screen headers
// Body / Label / UI: Manrope (sans-serif) — functional text, ingredients, steps, labels

// Add Newsreader and Manrope .ttf files to the Xcode project
// Register in Info.plist under "Fonts provided by application"

// MARK: — Type Scale
extension Font {
    // Serif — editorial moments
    static let displayLg  = Font.custom("Newsreader-Italic",     size: 36)  // Hero recipe title on full-bleed
    static let displayMd  = Font.custom("Newsreader-Italic",     size: 28)  // Screen titles
    static let headlineLg = Font.custom("Newsreader-SemiBold",   size: 22)  // Section headers
    static let headlineMd = Font.custom("Newsreader-Italic",     size: 18)  // Card titles in list
    static let serif      = Font.custom("Newsreader-Regular",    size: 16)  // Cultural notes, body serif

    // Sans — functional text
    static let labelXs    = Font.custom("Manrope-Bold",          size: 9)   // UPPERCASE tracking labels
    static let labelSm    = Font.custom("Manrope-SemiBold",      size: 11)  // Metadata, badges
    static let body       = Font.custom("Manrope-Regular",       size: 14)  // Body text
    static let bodySm     = Font.custom("Manrope-Regular",       size: 12)  // Descriptions
    static let bodyBold   = Font.custom("Manrope-SemiBold",      size: 14)  // Emphasized body
    static let uiMd       = Font.custom("Manrope-SemiBold",      size: 13)  // Button labels
    static let uiSm       = Font.custom("Manrope-Medium",        size: 11)  // Small UI
}
```

### Myanmar script rule

```swift
// NEVER use custom fonts for Myanmar script.
// iOS ships a capable system Myanmar font — always use .system()
// Minimum size: 16pt (the script is intricate and needs breathing room)

Text(recipe.titleMy ?? "")
    .font(.system(size: 17))
    .foregroundStyle(Color.secondaryText)   // Always adaptive — never hardcoded
    .lineSpacing(4)                         // Myanmar needs extra line height
```

### Typography hierarchy — apply in this exact order on every screen

1. Large serif italic screen title (Newsreader Italic, 28–36pt)
2. Myanmar script subtitle if available (system, 17pt, secondary color)
3. Uppercase tracking label (Manrope Bold, 9pt, tertiary color, 1.5 tracking)
4. Body content (Manrope Regular, 14pt)

---

## 4. Photo Integration — Full-Bleed Scrim

**This is the signature visual pattern of the app. Apply it consistently.**

### How it works

The recipe cover photo fills the entire card edge-to-edge with no padding, no border, no frame. A dark gradient scrim covers the bottom 45% of the image, giving enough contrast for white text to read at any time. The recipe title, Myanmar script, and metadata float on top of the scrim.

### Recipe hero card (recipe detail screen)

```swift
struct RecipeHeroView: View {
    let recipe: Recipe
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // — Photo layer
            if let path = recipe.coverImagePath,
               let image = ImageStore.load(path: path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fill)
                    .clipped()
            } else {
                // Placeholder — colored by category
                Rectangle()
                    .fill(placeholderColor(for: recipe.mealCategory))
                    .aspectRatio(4/3, contentMode: .fit)
            }

            // — Scrim layer (always dark regardless of color scheme —
            //   it sits on a photo, not on the app surface)
            LinearGradient(
                stops: [
                    .init(color: .clear,                        location: 0.35),
                    .init(color: Color.black.opacity(0.55),     location: 0.65),
                    .init(color: Color.black.opacity(0.82),     location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // — Text layer (always white — sits on the dark scrim)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.category?.uppercased() ?? "")
                    .font(.labelXs)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .tracking(1.5)

                Text(recipe.title ?? "")
                    .font(.displayLg)
                    .foregroundStyle(Color.white)               // Always white — on scrim

                if let titleMy = recipe.titleMy, !titleMy.isEmpty {
                    Text(titleMy)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white.opacity(0.7)) // Always white — on scrim
                }

                HStack(spacing: 12) {
                    Label("\(recipe.prepMinutes + recipe.cookMinutes) min", systemImage: "clock")
                    Label(recipe.difficulty ?? "", systemImage: "flame")
                }
                .font(.uiSm)
                .foregroundStyle(Color.white.opacity(0.8))      // Always white — on scrim
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))           // Hero = no radius
    }

    func placeholderColor(for category: MealCategory?) -> Color {
        switch category {
        case .soup:        return .plumMid
        case .noodles:     return .foliage
        case .curry:       return .terra
        case .salad:       return Color(hex: "#2a5c3f")
        case .dessert:     return Color(hex: "#7a2d8a")
        case .ceremonial:  return Color(hex: "#8B4A0A")
        default:           return .plumDeep
        }
    }
}
```

### Recipe list card (full-bleed in list)

```swift
struct RecipeListCard: View {
    let recipe: Recipe
    // Aspect ratio 3:2 for list cards — shorter than the detail hero
    // Same scrim pattern, smaller type

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo
            if let path = recipe.coverImagePath,
               let image = ImageStore.load(path: path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(3/2, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(RecipeHeroView.placeholder(for: recipe.mealCategory))
                    .aspectRatio(3/2, contentMode: .fit)
            }

            // Scrim
            LinearGradient(
                stops: [
                    .init(color: .clear,                    location: 0.3),
                    .init(color: Color.black.opacity(0.7),  location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Text — always white, always on scrim
            VStack(alignment: .leading, spacing: 3) {
                if let titleMy = recipe.titleMy, !titleMy.isEmpty {
                    Text(titleMy)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                Text(recipe.title ?? "")
                    .font(.headlineMd)
                    .foregroundStyle(Color.white)

                HStack(spacing: 8) {
                    // Region badge
                    Text(recipe.recipeRegion)
                        .font(.labelXs)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.terra.opacity(0.85))
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())

                    Text("\(recipe.prepMinutes + recipe.cookMinutes) min")
                        .font(.labelSm)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
```

### Grid view (2-column)

Same full-bleed scrim pattern but aspect ratio 1:1 (square). Shorter title, no Myanmar script in grid — only English. Myanmar appears on tap in detail view.

---

## 5. Photo Upload with Crop — Implementation

### Overview

When a user adds or edits a recipe, tapping the photo area opens:
1. `PhotosPicker` (iOS 16+) to select from library or camera
2. Immediately after selection → `ImageCropView` (custom SwiftUI view)
3. On crop confirm → `ImageStore.save()` to local file system
4. `recipe.coverImagePath` updated with the saved path

### CropShape options presented to user

```swift
enum CropAspect: String, CaseIterable {
    case hero    // 4:3  — used on recipe detail screen
    case card    // 3:2  — used on recipe list cards
    case square  // 1:1  — used in grid view

    var ratio: CGFloat {
        switch self {
        case .hero:   return 4/3
        case .card:   return 3/2
        case .square: return 1/1
        }
    }

    var label: String {
        switch self {
        case .hero:   return "Detail (4:3)"
        case .card:   return "List (3:2)"
        case .square: return "Grid (1:1)"
        }
    }
}
```

### ImageCropView — full implementation

```swift
import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let aspect: CropAspect
    var onConfirm: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedAspect: CropAspect

    init(image: UIImage, aspect: CropAspect = .hero,
         onConfirm: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void) {
        self.image = image
        self.aspect = aspect
        self._selectedAspect = State(initialValue: aspect)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // — Top bar
                HStack {
                    Button("Cancel") { onCancel() }
                        .font(.uiMd)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text("Crop Photo")
                        .font(.bodyBold)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Button("Done") { cropAndConfirm() }
                        .font(.uiMd)
                        .foregroundStyle(Color.terra)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // — Crop preview with gesture
                GeometryReader { geo in
                    let cropWidth  = geo.size.width - 40
                    let cropHeight = cropWidth / selectedAspect.ratio

                    ZStack {
                        // Image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cropWidth, height: cropHeight)
                            .scaleEffect(scale)
                            .offset(offset)
                            .clipped()

                        // Crop overlay (darkens outside crop area)
                        // Rule of thirds grid
                        RuleOfThirdsGrid()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            .frame(width: cropWidth, height: cropHeight)

                        // Crop border
                        Rectangle()
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: cropWidth, height: cropHeight)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, lastScale * value)
                                }
                                .onEnded { _ in lastScale = scale },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width:  lastOffset.width  + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in lastOffset = offset }
                        )
                    )
                }

                // — Aspect ratio picker
                HStack(spacing: 12) {
                    ForEach(CropAspect.allCases, id: \.self) { aspect in
                        Button(aspect.label) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAspect = aspect
                                // Reset position on aspect change
                                offset = .zero
                                lastOffset = .zero
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                        .font(.uiSm)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedAspect == aspect
                            ? Color.plumMid
                            : Color.white.opacity(0.15))
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)  // Crop view is always dark — it's a photo editing UI
    }

    func cropAndConfirm() {
        let cropped = cropImage(image, scale: scale, offset: offset, aspect: selectedAspect)
        onConfirm(cropped)
    }

    func cropImage(_ source: UIImage, scale: CGFloat, offset: CGSize, aspect: CropAspect) -> UIImage {
        let targetW: CGFloat = 1200
        let targetH: CGFloat = targetW / aspect.ratio

        UIGraphicsBeginImageContextWithOptions(CGSize(width: targetW, height: targetH), true, 1)
        defer { UIGraphicsEndImageContext() }

        let imgW = source.size.width  * scale
        let imgH = source.size.height * scale
        let drawX = (targetW - imgW) / 2 + offset.width * (targetW / UIScreen.main.bounds.width)
        let drawY = (targetH - imgH) / 2 + offset.height * (targetH / (targetW / aspect.ratio))

        source.draw(in: CGRect(x: drawX, y: drawY, width: imgW, height: imgH))
        return UIGraphicsGetImageFromCurrentImageContext() ?? source
    }
}

struct RuleOfThirdsGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Vertical lines
        p.move(to: CGPoint(x: rect.width / 3, y: 0))
        p.addLine(to: CGPoint(x: rect.width / 3, y: rect.height))
        p.move(to: CGPoint(x: rect.width * 2 / 3, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 2 / 3, y: rect.height))
        // Horizontal lines
        p.move(to: CGPoint(x: 0, y: rect.height / 3))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height / 3))
        p.move(to: CGPoint(x: 0, y: rect.height * 2 / 3))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height * 2 / 3))
        return p
    }
}
```

### Photo picker + crop wiring in CreateEditRecipeView

```swift
// State
@State private var selectedPhoto: PhotosPickerItem? = nil
@State private var rawImage: UIImage? = nil
@State private var showCropView = false

// PhotosPicker
PhotosPicker(selection: $selectedPhoto, matching: .images) {
    PhotoPlaceholderView(imagePath: recipe.coverImagePath)
}
.onChange(of: selectedPhoto) { item in
    Task {
        if let data = try? await item?.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            rawImage = ui
            showCropView = true
        }
    }
}
.fullScreenCover(isPresented: $showCropView) {
    if let raw = rawImage {
        ImageCropView(
            image: raw,
            aspect: .hero,
            onConfirm: { cropped in
                if let path = ImageStore.save(image: cropped, id: recipeId) {
                    recipe.coverImagePath = path
                    PersistenceController.shared.save()
                }
                showCropView = false
                rawImage = nil
            },
            onCancel: {
                showCropView = false
                rawImage = nil
            }
        )
    }
}
```

### ImageStore — updated for crop

```swift
// Services/ImageStore.swift
// Saves at 1200px wide, JPEG 80% quality — good balance of quality vs storage
// Filename uses UUID so each recipe has one image, overwritten on re-crop

import UIKit

struct ImageStore {
    private static var coversURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let covers = docs.appendingPathComponent("covers", isDirectory: true)
        try? FileManager.default.createDirectory(at: covers, withIntermediateDirectories: true)
        return covers
    }

    static func save(image: UIImage, id: UUID) -> String? {
        let url  = coversURL.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url, options: .atomic)
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

## 6. Dark Mode — Critical Rules

**The #1 bug in v1 was hardcoded black text in dark mode. This section prevents it from ever happening again.**

### The rule in one sentence

> Every `foregroundStyle`, `background`, and `fill` that touches an app surface (not a photo scrim) must use an adaptive color token — never a hardcoded hex or `Color.black` / `Color.white`.

### What goes on a scrim vs what goes on a surface

| Context | Text color | Why |
|---|---|---|
| On photo scrim (recipe hero, list card) | Always `Color.white` | Scrim is always dark regardless of mode |
| On app surface (settings, grocery list, form) | `Color.primaryText` (adaptive) | Must invert in dark mode |
| On plum background (CTA button) | Always `Color.white` | Button bg is always dark |
| On terra background (substitution panel light) | `Color.ink` (light) / `Color.white` (dark) | Terra is light in light mode, darker in dark |

### Adaptive surface patterns

```swift
// CORRECT — adapts automatically
Text("Mohinga")
    .foregroundStyle(Color.primaryText)

// CORRECT — on scrim, always white
Text(recipe.title ?? "")
    .foregroundStyle(Color.white)

// WRONG — hardcoded, invisible in dark mode
Text("Mohinga")
    .foregroundStyle(Color.black)

// WRONG — hardcoded, glaring in dark mode
Text("Mohinga")
    .foregroundStyle(Color(hex: "#1e0d22"))

// CORRECT card background
RoundedRectangle(cornerRadius: 16)
    .fill(Color.cardFill)

// WRONG card background
RoundedRectangle(cornerRadius: 16)
    .fill(Color(hex: "#f0e8dc"))
```

### Dark mode surface colors quick reference

```swift
// Page background
Color.appBackground
// = #fdf8f0 (light) / #0e0612 (dark)

// Card / list row fill
Color.cardFill
// = #f0e8dc (light) / #1a0d1e (dark)

// Input field / chip background
Color.inputFill
// = #f0e8dc (light) / #261630 (dark)

// Primary text
Color.primaryText
// = #1e0d22 (light) / #f2e8f4 (dark)

// Secondary text (descriptions, Myanmar script)
Color.secondaryText
// = #4a2d52 (light) / #c9a8d0 (dark)

// Tertiary text (metadata, labels)
Color.tertiaryText
// = #7a6080 (light) / #7a6080 dark (same — already muted)

// Dividers
Color.divider
// = plumLight 35% (light) / #3d2445 (dark)
```

### Nav bar dark mode

```swift
// Top app bar — always glassmorphism
.background(.ultraThinMaterial)
// ultraThinMaterial adapts automatically — cream-ish in light, dark in dark mode

// Bottom nav bar — same
.background(.ultraThinMaterial)

// Active nav item
// Light: plumPale background (#f2e8f4), plumDeep text (#4f055d)
// Dark:  darkElevated background (#261630), plumLight text (#c9a8d0)
```

### Grocery state colors — both modes

```swift
// State: needed — no tint, default surface
cardFill  // adaptive

// State: bought — plum tint, strikethrough
// Light: plumPale (#f2e8f4) bg, inkMuted text, strikethrough
// Dark:  darkElevated (#261630) bg, darkTextTertiary text, strikethrough
```

---

## 7. Layout & Spacing

### Screen layout rules

- Edge padding: **20pt** on all screens (never 16pt — too tight for the editorial feel)
- Card corner radius: **16pt** for recipe cards, **12pt** for smaller components
- Card gap in list: **14pt**
- Card gap in grid: **12pt**
- Section header spacing: **28pt** above, **12pt** below
- Bottom nav safe area: always add `safeAreaInset(edge: .bottom)`

### Recipe list — layout modes

**List view (default):** Full-bleed scrim cards stacked vertically. Width = screen width minus 40pt total padding. Aspect ratio 3:2.

**Grid view:** 2-column full-bleed scrim cards. Aspect ratio 1:1 (square). No gap between columns inside the grid — the cards themselves have corner radius that creates visual separation.

### Recipe detail — scroll layout

```
1. RecipeHeroView           — full width, 4:3 ratio, no padding, no corner radius (bleeds to edges)
2. Padding block (20pt)
3. Cultural note banner     — if isBuiltIn, terracotta left border, terraPale background
4. Serving stepper row      — right aligned
5. "Ingredients" header     — serif headline
6. Ingredient rows          — each with substitution expansion below if hasSubstitutions
7. "The Method" header      — serif headline, centered
8. Step rows                — numbered with plumDeep circles
9. Action row               — "Start Shopping" (primary) + "Share" (ghost)
```

---

## 8. Component Patterns

> Every pattern below has been designed to avoid the "AI app" look.
> If a component looks like it could have been generated by v0 or Bolt, redesign it.

---

### Category filters — underline tabs, not pills

Pills and capsules are the single most recognisable AI-app pattern. Replace them with a horizontally scrolling row of plain text labels. The active item gets a single 2pt line underneath it in `plumDeep`. No background fill. No border. Looks like a magazine section navigator.

```swift
struct CategoryFilterBar: View {
    @Binding var selected: MealCategory?
    let categories: [MealCategory?]  // nil = "All"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(categories, id: \.self) { cat in
                    CategoryTab(
                        label: cat?.rawValue.capitalized ?? "All",
                        isActive: selected == cat
                    )
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.18)) { selected = cat } }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

struct CategoryTab: View {
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(isActive ? .bodyBold : .body)
                .foregroundStyle(isActive ? Color.primaryText : Color.tertiaryText)

            // The underline — a Rectangle not a border
            Rectangle()
                .fill(isActive ? Color.plumDeep : Color.clear)
                .frame(height: 2)
        }
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}
```

---

### Ingredient rows — editorial two-column, no cards

Ingredient rows must NOT be cards. They are lines in a list — like a printed recipe. Quantity sits right-aligned in foliage green. A hairline separator (0.5pt) runs the full width below each row. No background fill, no corner radius, no shadow.

```swift
struct IngredientRow: View {
    let ingredient: Ingredient
    let scaledQuantity: Double
    @State private var showSubstitution = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                // Name
                Text(ingredient.name ?? "")
                    .font(.body)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                // Quantity — right aligned, foliage colored
                Text("\(formatQty(scaledQuantity)) \(ingredient.unit ?? "")")
                    .font(.bodyBold)
                    .foregroundStyle(Color.foliage)
            }
            .padding(.vertical, 14)

            // Substitution — inline italic, no panel
            if showSubstitution, let sub = ingredient.sortedSubstitutions.first {
                Text("→ \(sub.note ?? "")")
                    .font(.italic(.system(size: 13))())
                    .foregroundStyle(Color.terra)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Hairline separator — full width, no card needed
            Rectangle()
                .fill(Color.divider)
                .frame(height: 0.5)
        }
        // If substitution exists, show swap indicator inline
        .overlay(alignment: .trailing) {
            if ingredient.hasSubstitutions && !showSubstitution {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showSubstitution.toggle() }
                } label: {
                    Text("sub?")
                        .font(.labelXs)
                        .tracking(0.8)
                        .foregroundStyle(Color.terra.opacity(0.8))
                }
                .padding(.trailing, 0)
                .offset(y: -14)  // aligns to top of the row, overlapping the quantity
            }
        }
    }

    private func formatQty(_ q: Double) -> String {
        q.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(q)) : String(format: "%.1f", q)
    }
}
```

**Why this works:** The substitution text appears inline below the ingredient name as a terracotta italic line — it reads like a handwritten note in the margin of a cookbook. No rounded rectangle panel, no labeled section, no border. The "sub?" affordance is deliberately small and understated.

---

### Cultural note — serif quote block, no border

Cultural notes must feel like reading a book. Large decorative opening quotation mark in plum, body text in Newsreader Regular, attribution line in small caps. No background panel, no left border, no card.

```swift
struct CulturalNoteView: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Oversized decorative quote mark
            Text("\u{201C}")  // opening curly quote
                .font(.custom("Newsreader-Regular", size: 64))
                .foregroundStyle(Color.plumDeep.opacity(0.2))
                .frame(height: 36)  // clip excess vertical space from the glyph
                .clipped()
                .padding(.bottom, 4)

            // Body — Newsreader Regular, generous line height
            Text(note)
                .font(.custom("Newsreader-Regular", size: 16))
                .foregroundStyle(Color.secondaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // Attribution line — small caps style
            Text("— Traditional knowledge")
                .font(.labelXs)
                .tracking(1.2)
                .foregroundStyle(Color.tertiaryText)
                .padding(.top, 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        // No background, no border, no card — it floats on the page surface
    }
}
```

---

### Substitution note — inline, no panel

Do not use a panel, card, or bordered container for substitutions. The text appears directly below the ingredient row as a continuation — like a margin note.

```swift
// Inside IngredientRow (see above) — not a separate component
// Correct:
Text("→ \(sub.note ?? "")")
    .font(.italic(.system(size: 13))())
    .foregroundStyle(Color.terra)

// Wrong — never do this:
HStack(alignment: .top, spacing: 0) {
    Rectangle().fill(Color.terra).frame(width: 3)  // ← the banned left-border pattern
    VStack { Text("SUBSTITUTION")... }
}
.background(Color.terraPale)
.clipShape(RoundedRectangle(cornerRadius: 10))
```

---

### Primary CTA — floating bottom bar, not a button in the scroll

The "Start Shopping" action is the most important action in the app. It should not sit inside the scroll content as a flat rectangle button. It floats as a sticky bar at the bottom of the screen — always visible, always accessible. Uses `safeAreaInset(edge: .bottom)` so it sits above the home indicator.

```swift
// Applied to the ScrollView in RecipeDetailView:
.safeAreaInset(edge: .bottom) {
    RecipeActionBar(recipe: recipe, currentServings: servings)
}

struct RecipeActionBar: View {
    let recipe: Recipe
    let currentServings: Int

    var body: some View {
        HStack(spacing: 0) {
            // Start shopping — left 65% of the bar
            Button {
                GroceryMergeService.addRecipeToList(
                    recipe: recipe,
                    servings: currentServings,
                    context: PersistenceController.shared.container.viewContext
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "basket")
                        .font(.system(size: 15, weight: .medium))
                    Text("Start shopping")
                        .font(.uiMd)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.plumDeep)
            }

            // Divider — 1pt vertical line
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1)

            // Share — right 35% of the bar
            ShareLink(item: SharingService.encode(recipe: recipe) ?? URL(string: "https://")!) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                    Text("Share")
                        .font(.uiSm)
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.plumMid)
            }
        }
        .frame(height: 54)
        // No corner radius — bleeds edge to edge like a real bottom bar
        .background(Color.plumDeep)  // fills safe area below the bar
    }
}
```

---

### Serving size stepper — inline typographic control

Do not use a pill-shaped stepper container. The serving count is a typographic element — it lives inline with the "Ingredients" section header as a right-aligned control.

```swift
struct ServingStepper: View {
    @Binding var servings: Int
    let base: Int

    var body: some View {
        HStack(spacing: 0) {
            // Reduce
            Button {
                if servings > 1 { withAnimation { servings -= 1 } }
            } label: {
                Text("−")
                    .font(.custom("Newsreader-Regular", size: 22))
                    .foregroundStyle(servings > 1 ? Color.plumDeep : Color.tertiaryText)
                    .frame(width: 32, height: 32)
            }

            // Count + label — no background
            VStack(spacing: 0) {
                Text("\(servings)")
                    .font(.custom("Newsreader-SemiBold", size: 20))
                    .foregroundStyle(Color.primaryText)
                Text(servings == 1 ? "serving" : "servings")
                    .font(.labelXs)
                    .tracking(0.8)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(minWidth: 64)

            // Increase
            Button {
                withAnimation { servings += 1 }
            } label: {
                Text("+")
                    .font(.custom("Newsreader-Regular", size: 22))
                    .foregroundStyle(Color.plumDeep)
                    .frame(width: 32, height: 32)
            }
        }
        // No background fill, no border, no capsule shape
    }
}
```

---

### Step rows — numbered with typographic weight, not circles

Recipe steps use a large italic step number in plum, sitting to the left of the instruction text. No circle, no badge, no pill. The number is just a typographic element — it looks like a numbered list in a printed cookbook.

```swift
struct RecipeStepRow: View {
    let step: RecipeStep
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number — large italic, no circle
            Text("\(number)")
                .font(.custom("Newsreader-Italic", size: 36))
                .foregroundStyle(Color.plumDeep.opacity(0.25))
                .frame(width: 28, alignment: .trailing)
                .padding(.top, 2)

            // Instruction text
            Text(step.body ?? "")
                .font(.body)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        // Hairline between steps — same as ingredient rows
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 0.5)
        }
    }
}
```

---

### Grocery row — minimal, no card

Grocery rows must not be cards. They are list items. A checkbox on the left, name and quantity inline, hairline below. Bought items fade and get a strikethrough — the row does not move into a "card" or change its background to a tinted panel.

```swift
// See GroceryRowView in CLAUDE_v2.md (v2.2 section)
// Key constraint: no .background() fill on the row — the page surface IS the background
// The only visual change on toggle is: strikethrough + opacity 0.5 + checkbox fills plum
// No tinted card background change
```

---

### Section header — weight contrast only, no separator line

Section headers use typographic contrast to separate — a slightly larger Newsreader italic followed by the body. No horizontal rule above, no uppercase tracking label with a separator, no card wrapper around the section.

```swift
struct RecipeSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headlineLg)  // Newsreader SemiBold 22pt
            .foregroundStyle(Color.primaryText)
            .padding(.top, 28)
            .padding(.bottom, 4)
        // No separator, no background, no border
        // The size jump from body text IS the separator
    }
}
```

---

### Recipe card in list — full-bleed scrim, no rounded rectangle tint

List cards are full-bleed photos with a scrim (see Section 4). They must not have a colored background rectangle beneath the photo — the photo IS the card background. If there's no photo, the placeholder is a solid color fill (category-matched) — not a tinted rounded rectangle.

```swift
// Wrong — tinted background rectangle visible around the photo:
ZStack {
    RoundedRectangle(cornerRadius: 16).fill(Color.cardFill)  // ← banned
    AsyncRecipeImage(...)
}

// Correct — photo is the card, nothing beneath it:
AsyncRecipeImage(
    path: recipe.coverImagePath,
    aspectRatio: 3/2,
    placeholder: placeholderColor(for: recipe.mealCategory)
)
.clipped()
.clipShape(RoundedRectangle(cornerRadius: 16))
```

---

### Form inputs in CreateEditRecipeView — underline only, no box

Form fields use only a bottom border — no background box, no rounded rectangle container. The field text sits on the page surface, and a 1pt plumLight line runs below it. On focus the line becomes plumDeep.

```swift
struct RecipeFormField: View {
    let label: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.labelXs)
                .tracking(1.5)
                .foregroundStyle(Color.tertiaryText)

            TextField("", text: $text, axis: .vertical)
                .font(.body)
                .foregroundStyle(Color.primaryText)
                .focused($isFocused)
                .tint(Color.plumDeep)
                // No background fill — sits on page surface

            // Bottom line only
            Rectangle()
                .fill(isFocused ? Color.plumDeep : Color.plumLight.opacity(0.5))
                .frame(height: 1)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .padding(.vertical, 8)
    }
}
```

---

## 9. Do's and Don'ts

### Do
- Use `Color.primaryText`, `Color.secondaryText`, `Color.cardFill` everywhere on surfaces
- Use `Color.white` only when the view is provably on a dark scrim or dark button
- Use Newsreader italic for all recipe titles and screen headers
- Use `.ultraThinMaterial` for nav bars — never a solid fill
- Add `lineSpacing(4)` to all Myanmar script text
- Set a category-colored solid fill placeholder when there is no cover photo
- Always use `safeAreaInset(edge: .bottom)` for the action bar
- Use hairline separators (0.5pt `Rectangle`) between list rows — not cards
- Use the floating action bar (`RecipeActionBar`) — not a button inside the scroll
- Use underline tabs (`CategoryFilterBar`) — not capsule chips

### Don't
- Never use `Color.black`, `Color(hex: "#1e0d22")`, or any hardcoded dark color on a surface
- Never use `Color.white` on a surface (only on scrims and buttons)
- Never use custom fonts for Myanmar script — system font only
- Never show Myanmar script text in grid view cards (too small, too crowded)
- Never put a corner radius on the recipe hero image — it bleeds edge to edge
- Never hardcode `.light` or `.dark` colorScheme in a view unless it's the crop editor
- Never use a rounded rectangle with a colored left border (`Rectangle().frame(width: 3)` in an overlay)
- Never use capsule/pill chips with a solid fill background for category filtering
- Never wrap list rows in a `Color.cardFill` rectangle — rows sit on the page surface
- Never show a substitution in a bordered panel — inline italic text only
- Never put a background fill on `RecipeFormField` — bottom line only
- Never use step number circles — large italic Newsreader number only

---

## 10. File Checklist for Claude Code

When implementing any screen, verify:

- [ ] All text uses `Color.primaryText`, `Color.secondaryText`, or `Color.tertiaryText` (adaptive)
- [ ] All page backgrounds use `Color.appBackground` (adaptive)
- [ ] Text on scrim uses `Color.white` (intentional — scrim is always dark)
- [ ] Text on CTA buttons uses `Color.white` (intentional — button is always dark)
- [ ] Myanmar script uses `.system(size: 17+)` font, not Newsreader or Manrope
- [ ] Photo hero has scrim gradient with stops at 0.35, 0.65, 1.0
- [ ] Recipe list cards use 3:2 aspect ratio, grid cards use 1:1
- [ ] `ImageCropView` is presented as `.fullScreenCover` with `.preferredColorScheme(.dark)`
- [ ] Bottom nav bar uses `.ultraThinMaterial` background
- [ ] Category filter uses `CategoryFilterBar` (underline tabs) — NOT capsule chips
- [ ] Substitution text is inline italic in terracotta — NOT a bordered panel
- [ ] Cultural note uses `CulturalNoteView` (serif quote block) — NOT a left-border card
- [ ] Recipe detail action uses `RecipeActionBar` floating bar — NOT a button in the scroll
- [ ] Ingredient rows use `IngredientRow` with hairline separator — NOT cards
- [ ] Step numbers are large italic Newsreader — NOT circles or badges
- [ ] Form fields use `RecipeFormField` (bottom line only) — NOT background box inputs
- [ ] Grocery rows have NO background fill — strikethrough + opacity on toggle only
- [ ] No `RoundedRectangle` with a colored `overlay(alignment: .leading) { Rectangle() }` anywhere in the codebase

---

*End of DESIGN.md — Iris Garden · RecipeSaver v2.2*