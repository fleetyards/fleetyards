# Generate a consistent icon set for the hardpoint categories

Working plan for #5728. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every hardpoint category has its own icon from one newly drawn, `currentColor` set, resolved through one mapping that every caller uses.

## Open questions
- None. Icon format and power distribution are decided in the issue body.

## What changed

### Phase 1 — One renderer
1. `Components/CategoryIcon` moves to `Models/Hardpoints/CategoryIcon` (`HardpointCategoryIcon`). It is sized through `--hardpoint-category-icon-size` and inherits its colour from the caller.
2. The hardpoint list header, catalogue row, component detail page and `LoadoutView` all render it. The `v-if` chain in `Category/index.vue` is gone, and an iconless category gets an empty slot instead of a broken `<img>`.
3. The loadout modal tabs still read `categoryIcon()` through `FormTab`'s `icon`/`iconSrc`. That gets switched in Phase 2.

### Phase 2 — Draw the set
1. `categoryIcon()` returns a `Glyph` from `Record<HardpointCategoryEnum, Glyph>`, and `HardpointCategoryIcon` renders `DuotoneGlyph`. `FormTab`/`AnchorItems` take an `Icon` (`AppIcon`) and drop `iconSrc`.
2. Draw 42 glyphs on the 512 grid in one style (stroke weight, detail and proportions shared), covering the four categories without an icon (`scanners`, `salvagemunching`, `batteries`, `inventory`) and giving distinct drawings to `external_fuel_tanks`, `refuel_boom`, `weapon_mounts` and `jumpdrive`.
3. Check each one at 22–24px (hardpoint header, loadout tab) and at 52px (component detail page), in both themes.

### Phase 3 — Cleanup and specs
1. Delete `app/frontend/images/hardpoints/*.svg` and the unused `legend*.png` once nothing imports them.
2. Spec: every value of `HardpointCategoryEnum` resolves to a glyph; update `LoadoutModal/index.spec.ts:515-533` to the new return shape.
3. Power distribution: map each family to its category glyph, drop `FAMILY_ICON`, keep FA only for mining laser / tractor beam / towing beam.

## Intent Verification

- [x] **One icon per category**: 42 distinct glyphs, no FA fallbacks, no shared drawings.
- [x] **currentColor**: icons follow the theme and text colour, and no grayscale filter remains.
- [x] **One mapping**: the hardpoint list, catalogue, loadout modal and power distribution all resolve icons through `categoryIcon`, and the `v-if` chain is gone.
- [x] **Spec**: removing any enum entry from the map fails a spec.
- [x] **Legibility**: icons read at 22px and 52px.

## Key files

| File | Role |
|------|------|
| `app/models/hardpoint.rb:113` | `CATEGORIES`, the source of the enum |
| `app/frontend/frontend/components/Models/Hardpoints/categoryIcon.ts` | Current SVG + FA maps |
| `app/frontend/frontend/components/Models/Hardpoints/Category/index.{vue,scss}` | Hard-coded chain and grayscale filter |
| `app/frontend/frontend/components/Components/CategoryIcon/index.vue` | Catalogue row icon |
| `app/frontend/frontend/pages/components/[slug]/index.{vue,scss}` | 52px detail icon |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.vue` | Tab icons via `categoryTabIcon()` |
| `app/frontend/shared/components/TabNavView/AnchorItems/index.vue` | Renders `icon` / `iconSrc` |
| `app/frontend/frontend/components/Vehicles/LoadoutView/index.vue` | `categoryIcon("module")` in a heading |
| `app/frontend/frontend/components/Models/PowerDistribution/index.vue` | Its own family icon maps |
| `app/frontend/shared/components/DuotoneGlyph/{index.vue,glyph.ts}` | Glyph renderer to reuse |
| `app/frontend/frontend/components/Locations/KindIcon/glyphs.ts` | Prior art for an enum → glyph map |

## Not in scope (deferred)
- **Group panel titles**: they stay without icons (decided in the issue).

## Discovery Log

- **2026-10-16** Initial research and plan creation. `Category/index.vue` imports the enum from `fyAdminApi`; switch it to `fyApi`.
- **2026-10-16** Phase 1 swapped in the renderer before the glyph map, so each commit stays green. Drawing 42 glyphs first would have left the callers on the old union with nothing to render the new one. `turrets-dark.svg` and the legend PNGs are already unused.
- **2026-10-16** A tab icon is compared by identity: a glyph built inline per render re-registers its `FormTab` every time and Vue stops on "Maximum recursive updates". Glyphs are module constants, so only the FormTabs spec had to hoist one.
- **2026-10-16** Several drafts drew past the 512 grid (the hook, the maneuvering thrusters, the salvage rays) and clipped in the 22px header. Checked by rendering each glyph with room around it and reading the drawn bounds; all 42 stay inside.
- **2026-10-16** The loadout modal's missiles tab asked for `missiles`, which is no category; it now uses `missile_racks`.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
