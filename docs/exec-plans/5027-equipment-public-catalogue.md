# Equipment — a public catalogue with per-type figures

Working plan for #5027. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`/catalogue/equipment` lists the equipment catalogue with search, filters, sort and pagination, and every item has a page showing all the figures we hold for its type.

## Open questions
- None. D1 (everything, grouped by type), D4 (explicit `name_or_slug_cont`) and D7 (prices in this PR) are recorded in the issue body.

## What changed

### Phase 1 — Unique slug
1. `KeyedSlug` concern, extracted from `Component`, is now shared by `Equipment`.
2. The migration backfills slugs with an `sc_key` suffix for every member of a shared base, then adds a unique index. On the production dump: 4,921 rows and 138 shared bases, leaving 0 duplicates, and a save of all 4,921 rows moves no slug.

### Phase 2 — API: show, filters, sort
1. `GET /api/v1/equipment/:slug` applies `visible(false)`: a hidden item 404s, a retired one still answers.
2. `ransack_alias :name` is gone. Search goes through `nameOrSlugCont`, and the public and admin indexes both sort through ransack.
3. New sorts: `equipmentType`, `manufacturerName` and seven metrics. Every metric also has a `Gteq`/`Lteq` range. `EquipmentBuild::FILTERABLE` gains `damage_reduction`, `radiation_protection`, `g_force_tolerance` and `volume`.
4. New filters: `subTypeIn`, `weaponClassIn`, `slotIn`, `sizeIn` and `gradeIn`. New facet endpoints: `sub-types`, `weapon-classes` and `slots`. `types` is now documented.
5. The payload gains `*Label` fields for type, item type, sub-type, weapon class, slot and both compatibility fields. They come from `activerecord.attributes.equipment.*`, the same vocabulary as the filter endpoints.

### Phase 3 — Prices
1. `Uex::ItemPriceSyncer` and `Uex::ItemMatcher` are extracted from the component syncer. `Uex::EquipmentPriceSyncer` covers the sections Armor, Clothing, Personal Weapons and Undersuits.
2. A daily job at 06:30, an import model, an admin report and a notification type.

### Phase 4 — Frontend
1. The equipment tenant sits between components and commodities. The list page has typographic rows, a filter form, a sort bar and pagination.
2. `useEquipmentStats` holds a field list per type with `primary` marks, and drives both the detail page's metrics card and the row's lead metric.
3. The detail page shows a masthead (slot, size, grade, retired chip), metrics, details, availability and "Crafted from".
4. A `craftableRoute` helper links a blueprint's row, preview and page to the equipment or commodity it makes.
5. `catalogue/equipment/:slug` → `base#equipment` meta tags.

### Phase 5 — Labels in seven locales
1. Server: 84 item types, 22 sub-types and `kinetic`, in all seven locales.
2. Frontend: nav, title, headlines, `labels.equipment.*` (stats, sorts, availability), `labels.filters.equipment.*` and number units. The existing `labels.equipment.*` values outside `en` were English copies and are now translated.

## Intent Verification

- [x] **Unique slug.** No duplicate `equipment.slug` exists after the migration, and the unique index is present.
- [x] **Show endpoint.** `GET /api/v1/equipment/:slug` is documented in `swagger/v1/schema.yaml` and returns 404 for an unknown slug.
- [x] **Filters reachable.** The sub-type, weapon class, slot, size and grade filters work through the public index, and the slot and weapon-class facet endpoints respond.
- [x] **Honest sorting.** A sort orders the whole result set in SQL, with nulls last.
- [x] **List page.** `/catalogue/equipment` renders row lists with search, filters, sort and pagination.
- [x] **Detail page.** It shows the figures for the item's type, grouped and labelled, plus manufacturer, slot, size and grade.
- [x] **Blueprint link.** The item page lists the blueprints that make it, and blueprint rows link back to the item.
- [x] **Retired items.** A retired item's page shows a retired chip.
- [x] **Meta tags.** `catalogue/equipment/:slug` serves meta tags from `Frontend::BaseController`.
- [x] **Nav.** An Equipment tab appears in the catalogue nav.
- [x] **Labels.** Type, item-type, slot and weapon-class labels exist in all seven locales.
- [ ] **Browser check.** The pages have not been checked against real data in a browser yet.

## Not in scope (deferred)
- **Equipment history tab.** There is no `EquipmentBuildChange` for it to read.
- **Size and grade selects in the filter form.** Both are reachable through the API, but there are only five sizes and two grades.
- **`Uex::EquipmentMatcher::MAPPINGS`.** The first run will report four ambiguous skins (`P4-AR`, `Custodian`, `P8-SC` and `Gallant`, each paired with a `_tow` variant).

## Discovery Log

- **2026-09-25** Initial research and plan creation.
- **2026-09-25** `activerecord.attributes.equipment.*` already held translations for types, item types and slots in every locale. The labels reuse it rather than starting a new `filter.equipment.*` namespace.
- **2026-09-25** `storage` means different things by type: rounds on a gun or magazine, carrying capacity on apparel. The parser drops the unit, and the apparel figures are not consistent (a core reads 6.4, a jacket 1000), so no unit is shown for it. Volume is shown in µSCU, because in SCU a jacket is 0.0087 and the stat formatter rounds that to 0.
- **2026-09-25** The equipment price matcher matches against hidden items as well, because weapon skins are real shop items.

## Progress
- [x] Phase 1 — Unique slug
- [x] Phase 2 — API: show, filters, sort
- [x] Phase 3 — Prices
- [x] Phase 4 — Frontend
- [x] Phase 5 — Labels in seven locales
