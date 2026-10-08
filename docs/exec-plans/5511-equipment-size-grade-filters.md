# Size and grade filters for the equipment catalogue

Working plan for #5511. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The public equipment filter form offers size and grade multi-selects, fed by the values the current catalogue actually carries, writing `sizeIn` / `gradeIn`.

## What changed

### Phase 1 — Filter endpoints
1. `Equipment.size_filters` / `Equipment.grade_filters` over `build_facet(:size)` / `build_facet(:grade)`, labelled `filter.equipment.{size,grade}.label` (`Size 1`, `Grade 2`) in all 7 `filter.yml`.
2. `GET /filters/equipment/sizes` and `/filters/equipment/grades` in `config/routes/api/equipment_routes.rb` and `Api::V1::Filters::EquipmentController`.
3. Integration tests with the openapi DSL (`equipmentSizesFilters`, `equipmentGradesFilters`), regenerate `swagger/v1/schema.yaml` and the fyApi client.

### Phase 2 — Filter form
1. Two `BaseSelect`s in `app/frontend/frontend/components/Equipment/FilterForm/index.vue`, prefilled through `asList` like the others.
2. `labels.filters.equipment.size` / `.grade` in all 7 `labels.json` (edit by hand, no JSON round-trip — duplicate keys).
3. `index.spec.ts` for the form: a picked size/grade lands in the route query; a single-value query prefills as a list.

## Intent Verification

- [x] **Selects present** — size and grade multi-selects in the equipment filter form, writing `sizeIn` / `gradeIn`.
- [x] **Only real values** — options come from the current build; a value no visible item has is not offered.
- [x] **Locales** — labels in de, en, es, fr, it, zh-CN, zh-TW.
- [x] **Spec** — a vitest spec for the form.

## Key files

| File | Role |
|------|------|
| `app/models/equipment.rb` | `build_facet`, `fact_label`, the `*_filters` class methods |
| `app/controllers/api/v1/filters/equipment_controller.rb` | Filter option endpoints |
| `config/routes/api/equipment_routes.rb` | Filter routes |
| `test/integration/api/v1/filters_equipment_slots_test.rb` | Template for the new endpoint tests |
| `app/frontend/frontend/components/Equipment/FilterForm/index.vue` | The form |
| `app/frontend/frontend/components/Shops/FilterForm/index.spec.ts` | Template for the form spec |
| `app/frontend/translations/*/labels.json` | `labels.filters.equipment.*` |

## Discovery Log

- **2026-10-08** Initial research and plan creation. API already permits `size_in` / `grade_in`; both are ransackable. No filter endpoint exists for either.
- **2026-10-08** Live data in the workspace DB: sizes `1`–`5`, grades `1`–`2`, none missing on a visible build. String order is numeric order.

## Progress
- [x] Phase 1
- [x] Phase 2
