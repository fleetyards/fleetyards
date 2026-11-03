# Compare components and equipment side by side

Working plan for #6129. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`/compare/components/` and `/compare/equipment/` compare up to 8 items of one category side by side, with the ship compare's table, baseline delta, differences-only and best/worst highlights.

## What changed

### Phase 1 — Make the compare core generic
1. Lift `useCompareModels` into `useCompareItems(slugs, fetcher)`: the per-slug cache, incremental fetch, name sort and `AsyncStatus` stay; the ship version becomes a thin wrapper.
2. Make `Compare/Models/Table` take a generic header: a `columns` prop (`slug`, `name`, `image`, `subtitle`, `to`) instead of reading `Model` fields. The body is already driven by row kind. Ship compare must look identical afterwards (pixel diff).
3. Move the toolbar and legend out of `pages/compare.vue` into a shared `CompareLayout` so all three pages use the same one.
4. Delete the dead `stores/compare.ts`.

### Phase 2 — Components compare
1. ~~Add `slug_in` to components~~ — not needed: every compared item is fetched by its own detail request, as ships are, through `useCompareItems`.
2. Add `sections/component.ts`: turn `useComponentStats` / `useHardpointStats` output (`HardpointStat.key` + `raw`) into `value` rows, grouped by `stat.group`, using the union of keys across the compared items. Add a per-key direction map, because higher is not always better (e.g. heat, power draw, spool time). Durability goes in its own section.
3. Add the page, `useCompareCatalogue` (query key `components`), and `Compare/CataloguePickerModal`, which reuses the `Logistics/ItemPicker` row and is locked to the set's category.
4. Entry point: a "Compare" button on the component detail page. The list rows have no action menu; see Not in scope.

### Phase 3 — Equipment compare
1. Add `sections/equipment.ts` as a flat `CompareMetric<Equipment>` list per `equipmentType`, following the vocabulary in `useEquipmentStats`, with directions.
2. Add the page, filters (query key `equipment`), and a picker locked to `equipmentType` plus the worn slot or the item type. Not `weaponClass`: it is ballistic or energy, which files a pistol with a sniper rifle.
3. The same detail-page entry point as for components.

### Phase 4 — Share image
1. Generalise `CompareController`, `CompareImage` (`MAX_SHARE_MODELS`) and `schemas/compare_share.rb` so they take a subject kind (ships, components, equipment) and a slug list. Keep the existing ship request shape working, because shared links already exist.
2. `compare_images.kind` scopes slug sets and share keys per catalogue; the OG composite reuses the store images (735 components have one, no equipment does).
3. `CompareShareInput` takes `models`, `components` or `equipment`; `models` is no longer required, which relaxes the request rather than breaking it.
4. `useCompareShareUrl` serves the ship actions and the new pages.

### Phase 5 — Routes, i18n, tests
1. Add routes to `pages/routes.ts` and `types/routes.ts` (`FrontendSimpleRoutes`), with `meta.title` in both `nav.*` and `title.*`.
2. Translate every new key in all 7 locales by hand.
3. Vitest specs for both section builders (rows, directions, empty sections dropping out) and for the category lock. Add a Playwright spec following `Ship.spec.ts:33-35`: from a detail page to the compare URL.

## Intent Verification

- [x] **Components compare** — two shields from the component list show side by side at `/compare/components/?components[]=a&components[]=b`
- [x] **Equipment compare** — two rifles show side by side, and the picker offers only rifles
- [x] **One category** — the picker never offers a different category; a mixed URL falls back to one category
- [x] **Shareable URL** — reloading the URL restores the same set
- [ ] **Modes** — "differences only" hides uniform rows; baseline mode shows ±% with correct better/worse colours
- [x] **Empty sections** — sections with no data for any item are not shown
- [x] **Ship compare unchanged** — pixel diff of `/compare/` before and after, at 1440 and 430 wide: no difference
- [ ] **Share** — the share button on both new pages produces an image of the compared items; old ship share links still work
- [x] **Locales** — no "translation missing" in any of the 7 locales

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/compare.vue` | Ship compare page, the template for the new ones |
| `app/frontend/frontend/components/Compare/types.ts` | `CompareSection`, `CompareMetric<T>`, `valueRows`; already generic |
| `app/frontend/frontend/components/Compare/Models/Table/index.vue` | Table; the header is ship-specific |
| `app/frontend/frontend/composables/useCompareModels.ts` | Becomes `useCompareItems` |
| `app/frontend/frontend/composables/useComponentStats.ts`, `useHardpointStats.ts` | Component stats (`HardpointStat` with key and raw value) |
| `app/frontend/frontend/composables/useEquipmentStats.ts` | Equipment vocabulary per `equipmentType` |
| `app/frontend/frontend/components/Logistics/ItemPicker/index.vue` | Picker base with category props |
| `app/models/compare_image.rb`, `app/controllers/api/v1/compare_controller.rb` | Share links per kind |
| `app/frontend/frontend/pages/routes.ts`, `app/frontend/frontend/types/routes.ts` | Routes |

## Not in scope (deferred)
- **Comparing across categories** — rejected in the issue.
- **A compare action on list rows** — component and equipment rows carry no action menu, so one needs a design decision first. The lists link their empty compare page from the header instead.

## Discovery Log

- **2026-11-03** Initial research and plan creation. `stores/compare.ts` is dead. Components have no `slug_in`; equipment has `slugIn`. `useEquipmentStats` returns stats without `key`/`raw`.
- **2026-11-03** The default baseline was whichever item's request answered first, so it differed between runs and viewports. It is now the first column unless the reader picks one.
- **2026-11-03** Weapon `weaponClass` is ballistic/energy; `itemType` (rifle, smg, pistol) is the grain a comparison wants.

## Progress
- [x] Phase 1 — Generic compare core
- [x] Phase 2 — Components compare
- [x] Phase 3 — Equipment compare
- [x] Phase 4 — Share image
- [x] Phase 5 — Routes, i18n, tests
- [x] Compare switch: a segmented control beside the add button, over the ships, components and equipment children of `/compare/`
