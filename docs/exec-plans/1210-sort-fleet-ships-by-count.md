# Suggestion: Be able to sort by highest number the ships of the fleets

Working plan for #1210. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A fleet's grouped ship list (public and private) can be sorted by how many of each model the fleet holds, matching the "3x" counts shown on the rows.

## Open questions
- None.

## What changed

### Phase 1 — Backend sort
1. Add `"vehiclesCount asc"` / `"vehiclesCount desc"` to `FleetVehicle::ALLOWED_SORTING_PARAMS`. The name has no `model_` prefix, so `model_sorts` never forwards it to `Model.ransack`.
2. Grouped branch of both `Api::V1::FleetVehiclesController#index` and `Api::V1::Public::FleetVehiclesController#index`: join a per-model `COUNT(DISTINCT vehicles.id)` subquery built from the filtered scope, and order by it with `models.name` as the tie-breaker. The logic goes in one shared helper (a `FleetVehicle` class method or `FleetVehicleFiltersConcern`) because the two controllers duplicate it today.
3. Ungrouped branch: the count sort falls back to the default sort (see the issue's Decisions).

### Phase 2 — Schema + client
1. Regenerate `swagger/v1/schema.yaml`. `FleetVehicleSortEnum` picks the new value up from `ALLOWED_SORTING_PARAMS`.
2. Run orval so `FleetVehicleSortEnum.ts` has the new value. Restart the dev server before testing by hand, because the running server caches the old schema.

### Phase 3 — Frontend
1. Add a `FleetSortFieldsEnum` member in `stores/fleet.ts`, and in `stores/publicFleet.ts` if it keeps its own list.
2. Label it in `useFleetSortFields.ts` and show it only while the list is grouped.
3. Add the label to all 7 `labels.json` locales by hand.

### Phase 4 — Tests
1. `fleets_vehicles_index_test.rb`: grouped count desc and asc (3x A, 1x B, 2x C sorts to A, C, B), plus the ungrouped behaviour.
2. `public_fleets_vehicles_test.rb`: grouped count sort.
3. `fleet_vehicle_test.rb`: `model_sorts` drops the count sort.

## Intent Verification

- [ ] **Grouped count sort** — with the list grouped, sorting by count desc shows the most-held model first. The order matches the "Nx" labels.
- [ ] **Filters respected** — the counts used for sorting follow the active filters, the same way the model-counts endpoint does.
- [ ] **Public fleet page** — the public ship list offers the same sort.
- [ ] **Ungrouped** — no 400 or 500 when the count sort is chosen while ungrouped.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_vehicle.rb:46-61` | Sort whitelist and `model_sorts` |
| `app/controllers/api/v1/fleet_vehicles_controller.rb:53-64` | Grouped branch (private) |
| `app/controllers/api/v1/public/fleet_vehicles_controller.rb:38-49` | Grouped branch (public) |
| `app/controllers/api/v1/fleet_stats_controller.rb` (`model_counts`) | How the displayed counts are computed |
| `app/api_components/v1/schemas/sorts/fleet_vehicle_sort_enum.rb` | Enum source |
| `app/frontend/frontend/stores/fleet.ts:29-46` | `FleetSortFieldsEnum` and default chips |
| `app/frontend/frontend/composables/useFleetSortFields.ts` | Sort labels |
| `app/frontend/frontend/components/Fleets/ShipsList/index.vue`, `PublicShipsList/index.vue` | The lists |
| `test/integration/api/v1/fleets_vehicles_index_test.rb:103-149` | Existing sort tests |

## Not in scope (deferred)
- **Count in the grouped `models.jbuilder` response** — would remove the separate model-counts request, but it changes the API shape and the issue doesn't need it.

## Discovery Log

- **2026-09-25** Initial research and plan creation. Nothing sorts by an aggregate count today. The closest precedents are the subquery ransackers in `model.rb:317-334` and `component.rb:385-405`.

- **2026-09-25** Ransack's `evaluate` runs `except(:order)` before applying its sorts, so the count order has to be put in front after `.result` with `reorder`. An `order` before the ransack call is silently dropped.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
