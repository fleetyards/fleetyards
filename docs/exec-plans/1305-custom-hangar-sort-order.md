# Hangar: Allow custom sorting of ships in the Users Hangar

Working plan for #1305. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Users drag vehicles in their hangar into a custom order, pick the hangar's default order, and the public hangar shows that order.

## Open questions
- None. Move input, page scope, where the default is set, and the grid-only scope are decided in the issue body.

## What changed

### Phase 1 — API: move endpoint
1. `member { put :move }` in `config/routes/api/vehicles_routes.rb`.
2. `VehiclesController#move`: add it to `set_vehicle`, `authorize!`, `move_to!`, then 204. `VehiclePolicy` already allows it through `default_rule :manage?`.
3. Input component `app/api_components/v1/schemas/inputs/vehicle_move_input.rb`, `{afterId}` or `{beforeId}` (uuid), exactly one.
4. Request test `test/integration/api/v1/vehicles_move_test.rb`, with an `api_path` block and responses 204/401/403/404. It checks that another user's vehicle cannot be moved. Then `bin/generate-schema` and orval.

### Phase 2 — API: rank sort + per-user default order
1. Add `rank asc`/`rank desc` to `Vehicle::ALLOWED_SORTING_PARAMS` and `rank` to `ransackable_attributes`. The sort enum follows automatically, the admin schema included.
2. A new `users.hangar_default_sort` column plus an enum component, permitted in `users#update`, serialized in `_base.jbuilder`, and added to the `User`/`UserUpdateInput` components by hand.
3. `hangars#show` and `public/hangars#show` pass the owner's default as the `sorting_params` fallback.
4. Tests in `hangar_test.rb`, `public_hangars_show_test.rb` and `users_me_test.rb`.

### Phase 3 — Frontend: drag and drop
1. Add a "custom" (rank) entry to `useVehicleSortFields`.
2. A grip on `Vehicles/Panel` (`#heading-actions`), shown through a `sortable` prop, like `SquadronPanel`.
3. `pages/hangar/index.vue`: `Grid :sortable="canSort" sort-handle=...`, where `canSort` means the rank sort is active and no filters are set. Plus an optimistic `onSort` that rolls back on failure, as in the squadrons page.
4. SortBar `default-sort` comes from the user's setting instead of `"name asc"`, on both the own and the public hangar.

### Phase 4 — Frontend: default order setting
1. A select on `pages/settings/hangar.vue`, with locale keys in all 7 locales.

## Intent Verification

- [ ] **Move endpoint:** `PUT /api/v1/vehicles/:id/move` reorders and returns 204. Another user's vehicle returns 403/404.
- [ ] **Rank sort:** the hangar can be sorted by rank from the sort bar.
- [ ] **Drag and drop:** dragging a card by its grip persists the new order across a reload. It is disabled when filters are set or a non-rank sort is active.
- [ ] **Default order:** the user's chosen default order applies when no `s` is given, in the own hangar and the public hangar.
- [ ] **Tests:** a request test for move (including authorisation) and a vitest spec for the hangar reorder.

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/fleet_squadrons_controller.rb` | `move` pattern to copy |
| `test/integration/api/v1/fleets_squadrons_move_test.rb` | Request-test pattern |
| `app/models/vehicle.rb` | `rank!`, sorting constants, ransackable attrs |
| `app/controllers/api/v1/vehicles_controller.rb` | New `move` action |
| `app/controllers/api/v1/hangars_controller.rb` | Own hangar sort fallback |
| `app/controllers/api/v1/public/hangars_controller.rb` | Public hangar sort fallback |
| `app/helpers/ransack_helper.rb` | `sorting_params(model, sorts, fallback)` |
| `app/controllers/api/v1/users_controller.rb` | Permit the default-order column |
| `app/frontend/pages/hangar/index.vue` | Grid + table, sortable wiring |
| `app/frontend/pages/fleets/[slug]/squadrons/index.vue` | `onSort` pattern (+ spec) |
| `app/frontend/components/Vehicles/Panel/index.vue` | Grip |
| `app/frontend/shared/components/base/Grid/index.vue` | sortablejs grid |
| `app/frontend/composables/useVehicleSortFields.ts` | Sort options |
| `app/frontend/pages/settings/hangar.vue` | Server-backed hangar settings |

## Not in scope (deferred)
- **Drag and drop on the sort header to set the default:** a select covers it. This becomes its own issue if it is still wanted.

## Discovery Log

- **2026-09-25** Initial research and plan creation. The rank group spans wishlist, hidden and loaners, so a view-relative `position` would be wrong.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
