# Starter Content Release Process

This document defines how to ship built-in recipe changes without wiping all user data.

## Files
- `RecipeSaver/Resources/StarterRecipes.json`: baseline seed for fresh installs.
- `RecipeSaver/Resources/StarterContentUpdates.json`: incremental updates for existing installs.

## Runtime Behavior
- Fresh install:
  - App seeds built-in content from `StarterRecipes.json`.
- Existing install:
  - App reads `StarterContentUpdates.json`.
  - If `targetVersion` is newer than installed version, it applies each update in order.
  - Applied version is stored in `UserDefaults` key `starterContentVersionV1`.

## Manifest Schema
```json
{
  "targetVersion": 2,
  "updates": [
    {
      "version": 2,
      "deleteRecipeKeys": ["cover:StarterBurmeseTofu"],
      "upsertRecipes": [
        {
          "title": "...",
          "titleMy": "...",
          "desc": "...",
          "descMy": "...",
          "category": "...",
          "region": "...",
          "difficulty": "...",
          "prepMinutes": 10,
          "cookMinutes": 20,
          "baseServings": 4,
          "culturalNote": "...",
          "coverImageName": "Starter...",
          "ingredients": [...],
          "steps": [...]
        }
      ]
    }
  ]
}
```

## Recipe Keys
Keys are normalized (trimmed + lowercased) and matched by:
- `cover:<coverImageName>` when `coverImageName` exists
- otherwise `title:<title>`

Use `deleteRecipeKeys` when a key changes (for example, renaming `coverImageName`).

## Authoring Rules
1. Never edit already shipped update versions.
2. Add a new update object with `version = previous + 1`.
3. Set `targetVersion` to the latest version.
4. For changed built-in recipes, include full recipe payload in `upsertRecipes`.
5. For renamed keys, add old keys to `deleteRecipeKeys`.
6. Keep updates idempotent: reapplying should produce the same final state.

## Release Checklist
1. Update `StarterRecipes.json` for fresh-install baseline.
2. Add a new incremental update entry in `StarterContentUpdates.json`.
3. Validate JSON:
   - `ruby -rjson -e 'JSON.parse(File.read("RecipeSaver/Resources/StarterContentUpdates.json"))'`
4. Run app build and launch once on a simulator with existing data.
5. Verify edited built-in recipes updated and user-created recipes unaffected.

## Notes
- The app optionally bootstraps from a bundled SQLite seed store (`RecipeSaverSeed.sqlite`) if present.
- If no bundled seed store exists, the app falls back to normal Core Data store creation.
