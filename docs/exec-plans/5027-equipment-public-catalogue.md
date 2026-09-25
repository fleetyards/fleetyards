# Equipment — a public catalogue with per-type figures

Working plan for #5027. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`/catalogue/equipment` lists the equipment catalogue with search, filters, sort and pagination, and every item has a page showing all the figures we hold for its type.

## Open questions
- **D1 — scope.** Everything (4,504), stat gear only (2,722), or gear with a manufacturer? This must be one predicate (a `catalogued` scope, as components has) that both index and show apply. It sizes the D6 translation job.
- **D4 — sorting.** Should `ransack_alias :name, :name_or_slug` be replaced by an explicit `name_or_slug_cont` predicate (a public-query change; check callers such as `EquipmentPicker`), or should sorting happen outside ransack?
- **D7 — prices.** Does equipment join the components UEX price phase, or stay out of scope?
- **History tab.** There is no `EquipmentBuildChange`, so there is no history route like `component-history`. Confirm that is deferred.

## What changed

### Phase 1 — Unique slug
1. Migration modelled on `db/migrate/20260917160000_add_unique_slug_to_components.rb`: rows that share a base slug get `-<sc_key>`, leftover collisions get `-2`, `-3` and so on, then `add_index :equipment, :slug, unique: true`.
2. Port `update_slugs` / `slug_settled?` / `keyed_slug` from `Component` (`component.rb:651-722`) to `Equipment`, or share them through a concern.
3. Model tests for collision handling.

### Phase 2 — API: show, filters, sort
1. `resources :equipment, only: %i[index show], param: :slug`, a `show` action (find by slug, with no `current_version` filter so retired items stay reachable), and `show.jbuilder`.
2. `test/integration/api/v1/equipment_show_test.rb` modelled on `components_show_test.rb` (200/404), then regenerate the schema.
3. Add a `catalogued` scope (the D1 predicate) and apply it in index and show.
4. Permit `sub_type_in`, `weapon_class_in`, `slot_in`, `size_in` and `grade_in` (plus metric `_gteq`/`_lteq` where D3 wants them), and update `EquipmentQuery`.
5. Filter endpoints `filters/equipment/weapon-classes` and `filters/equipment/slots` that call the existing `weapon_class_filters` / `slot_filters`.
6. Sorting per D4: `normalize_sort_params` + `sorting_params`, a widened `ALLOWED_SORTING_PARAMS`, fact/metric ransackers, and `sorts` in `EquipmentQuery`.

### Phase 3 — Frontend list
1. Add an `equipment` tenant to `pages/catalogue/tenants.ts` and `nav.catalogue.equipment` in every locale.
2. `pages/equipment/routes.ts`, `index.vue`, and `[slug]` shell pages mirroring `pages/components/`.
3. `useEquipmentFilters`, `useEquipmentSortFields`, and an `Equipment/Row` built on `RowListItem`.

### Phase 4 — Frontend detail
1. `useEquipmentStats`: a field list per `equipment_type` with `primary` marks, rendered through `MetricsCard` hero/rest tiles.
2. A detail page with breadcrumbs, manufacturer, slot, size and grade, a `retired` chip, and `Availability` with an equipment scope.
3. A "crafted from" card via `useBlueprintsQuery({ craftableTypeEq: EQUIPMENT, craftableIdEq })`, plus an `Equipment` link branch in `Blueprints/Row` and `Blueprints/Preview`.
4. The Rails route `catalogue/equipment/:slug` → `base#equipment` meta tags, and a frontend route test.

### Phase 5 — Labels in seven locales
1. `filter.equipment.{type,item_type,slot,weapon_class}_filters` in `config/locales/*/filter.yml`, covering all seven locales and translated by hand.
2. `labels.equipment.*` (stat names, retired, availability) in `app/frontend/translations/*/labels.json`.

## Intent Verification

- [ ] **Unique slug.** No duplicate `equipment.slug` exists after the migration, and the unique index is present.
- [ ] **Show endpoint.** `GET /api/v1/equipment/:slug` is documented in `swagger/v1/schema.yaml` and returns 404 for an unknown slug.
- [ ] **Filters reachable.** The sub-type, weapon class, slot, size and grade filters work through the public index, and the slot and weapon-class facet endpoints respond.
- [ ] **Honest sorting.** A sort orders the whole result set across pages, not just the current page.
- [ ] **List page.** `/catalogue/equipment` renders row lists with search, filters, sort and pagination.
- [ ] **Detail page.** It shows the figures for the item's type, grouped and labelled, plus manufacturer, slot, size and grade.
- [ ] **Blueprint link.** The item page lists the blueprints that make it, and blueprint rows link back to the item.
- [ ] **Retired items.** A retired item's page shows a retired marker.
- [ ] **Meta tags.** `catalogue/equipment/:slug` serves meta tags from `Frontend::BaseController`.
- [ ] **Nav.** An Equipment tab appears in the catalogue nav.
- [ ] **Labels.** Type, item-type, slot and weapon-class labels exist in all seven locales.

## Key files

| File | Role |
|------|------|
| `app/models/equipment.rb`, `app/models/equipment_build.rb` | model, facts, ransackers, facets, `FILTERABLE` |
| `app/controllers/api/v1/equipment_controller.rb` | index today; gains show and sort |
| `app/controllers/api/v1/filters/equipment_controller.rb` | facet endpoints |
| `config/routes/api/equipment_routes.rb` | `param: :slug`, new filter routes |
| `app/views/api/v1/equipment/` | gains `show.jbuilder` |
| `app/api_components/v1/schemas/queries/equipment_query.rb` | query schema (filters, `sorts`) |
| `db/migrate/20260917160000_add_unique_slug_to_components.rb` | slug migration to copy |
| `app/controllers/api/v1/components_controller.rb`, `app/helpers/ransack_helper.rb` | sort pattern |
| `app/frontend/frontend/pages/catalogue/tenants.ts` | tenant registry / nav |
| `app/frontend/frontend/pages/components/**`, `composables/useComponentStats.ts` | list/detail/stat pattern |
| `app/frontend/frontend/components/Blueprints/{Row,Preview}/index.vue` | reverse link branch |
| `config/routes/frontend_routes.rb`, `app/controllers/frontend/base_controller.rb` | meta-tag route |
| `config/locales/*/filter.yml`, `app/frontend/translations/*/{labels,nav}.json` | labels |

## Not in scope (deferred)
- **Equipment history tab.** No `EquipmentBuildChange` exists to read.
- **Prices (D7).** Pending the decision. `Uex::PriceSyncer` syncs models only.

## Discovery Log

- **2026-09-25** Initial research and plan creation. Findings: components built the slug backfill inside the schema migration rather than in db/data. `Equipment` has no `has_many :blueprints`, and reverse links go through the Blueprint `craftable_*` query. `_base.jbuilder` already emits `retired`.

## Progress
- [ ] Phase 1 — Unique slug
- [ ] Phase 2 — API: show, filters, sort
- [ ] Phase 3 — Frontend list
- [ ] Phase 4 — Frontend detail
- [ ] Phase 5 — Labels in seven locales
