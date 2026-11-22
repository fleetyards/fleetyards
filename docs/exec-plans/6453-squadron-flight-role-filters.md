# Squadron and flight role filters set by the lead

Working plan for #6453. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A squadron or team can carry a role filter (classifications and/or focus) that narrows its ship pool, and every place that reads that pool respects it.

## Open questions

- Member-side per-squadron ship choice (all / group / picked): keep as is in this PR? Proposed: keep, revisit once the filter exists.

## What changed

### Phase 1 — Data and pool
1. Migration: `fleet_squadrons.classifications` and `fleet_squadrons.foci`, `varchar[]`, default `[]`, not null.
2. `FleetSquadron`: normalize classifications (`Model.normalize_value_for`) and foci (`Model.ordered_foci`), validate classifications against `Model::CLASSIFICATIONS`, `include FociList`, `role_filtered?`.
3. `FleetSquadron.vehicle_ids_for`: join the squadron and the vehicle's model and add the per-squadron condition (`cardinality(classifications) = 0 OR models.classification = ANY(...)` and the same overlap for foci), keeping the `squadron_rows` alias the callers scope on.

### Phase 2 — API
1. `FleetSquadronPolicy`: permit `classifications`, `foci`; a rule letting the squadron's lead rank (`actor_rank`, as in `FleetSquadronMembershipPolicy`) update only the filter.
2. Existing flight ships and slot candidates stay valid when the filter tightens: the pool check runs only when the vehicle changes.
2. OpenAPI: `fleet_squadron.rb`, `fleet_squadron_update_input.rb`, `fleet_squadron_create_input.rb` (`ModelFocusEnum` items); jbuilder `_base` with `focusLabels`.
3. `bin/generate-schema`, `bin/generate-clients`.

### Phase 3 — Frontend
1. Squadron form step (or a section in `SquadronDetailsFields`) with `ModelClassificationSelect` and `ModelFocusSelect`; `useSquadronForm` state.
2. Overview shows the active filter.
3. Translations in every locale.

### Phase 4 — Tests
1. `fleet_vehicle_filters_concern_test.rb`: filter by classification, by focus, both, empty filter.
2. `fleets_squadrons_update_test.rb`: set/clear filter, invalid classification/focus, permission.
3. Flight lineup and ship request tests: a ship outside the filter is refused.
4. `useSquadronForm.spec.ts`.

## Intent Verification

- [ ] **Filter narrows the pool** — the squadron's ship count and the fleet ships list with `squadronSlugIn` drop ships outside the filter.
- [ ] **Flight picker respects it** — a ship outside the filter can't be added to a flight or slot.
- [ ] **No filter is unchanged** — squadrons without a filter behave exactly as before.
- [ ] **Fleet sharing untouched** — member fleet share options are unchanged.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_squadron.rb` | Filter columns, `vehicle_ids_for` |
| `app/models/concerns/foci_list.rb` | Focus validation |
| `app/models/mission_ship.rb` | Flight ship validation via the pool |
| `app/models/fleet_squadron_ship_request.rb` | Ship request validation via the pool |
| `app/controllers/concerns/fleet_vehicle_filters_concern.rb` | `squadronSlugIn` filter |
| `app/policies/fleet_squadron_policy.rb` | Params and edit rights |
| `app/api_components/v1/schemas/fleets/squadrons/fleet_squadron.rb` | Schema |
| `app/api_components/v1/schemas/inputs/fleet_squadron_update_input.rb` | Input schema |
| `app/views/api/v1/fleet_squadrons/_base.jbuilder` | Output |
| `app/frontend/frontend/composables/useSquadronForm.ts` | Form state |
| `app/frontend/frontend/components/Fleets/Squadrons/SquadronDetailsFields/index.vue` | Form fields |
| `app/frontend/components/base/ModelClassificationSelect/index.vue` | Reused select |
| `app/frontend/components/base/ModelFocusSelect/index.vue` | Reused select |

## Not in scope (deferred)

- **Per-flight filter** — decided against for now (see issue); flights inherit the squadron's pool.

## Discovery Log

- **2026-11-21** Initial research and plan creation. Pool already flows through `vehicle_ids_for` for all five readers, so one SQL change covers list, counts, flight picks, slot candidates and ship requests. Precedent for stored criteria: `MissionShip`/`FleetEventShip` (single classification + foci array), `HangarPlanSlot.filters` (jsonb, multi classification).

## Progress

- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
