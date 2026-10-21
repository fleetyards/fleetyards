# Our own vocabulary of ship foci

Working plan for #5895. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A ship carries a list of foci from a fixed vocabulary plus a stealth flag, every source maps onto them, and every filter, slot and page reads the list.

## Open questions

None. The column strategy, the dropped sort and the game-file roles are decided in the issue.

## What changed

### Phase 1 — Vocabulary and storage
1. `Model::FOCI` (the 40 keys) and the umbrella rule: any fighter tier adds `fighter`, any capital class adds `warship`.
2. `Models::FocusMapping`: a raw source string to keys plus stealth, splitting `X / Y` and dropping size tiers except fighters.
3. Schema migration: `foci` string array with a GIN index on `models`, `fleet_event_ships` and `mission_ships`, plus `models.stealth` and `models.sc_role`.
4. A data migration with its own frozen copy of the mapping, plus the per-ship decisions from the issue.
5. Validation that each key is in `FOCI`, a normaliser that adds the umbrellas, and the same on the slot models.

### Phase 2 — Loaders
1. `Rsi::ModelsLoader`: keep `rsi_focus` raw, map onto `foci` and `stealth`, and log unknown values.
2. `ScData::Loader::ModelsLoader`: store `role` in `sc_role`, and fill `foci` when empty.
3. `lib/tasks/missions.rake` and `fleet_event.rb` copy slot foci.

### Phase 3 — API
1. Filters: `focus_filters` from `FOCI` with translated labels, `focusIn` as an array overlap (ransacker or scope) on models, hangar and fleet vehicles, and a `stealth` filter.
2. Schemas, inputs, jbuilder views and permitted params (admin `foci: []`, `stealth`), plus raw `rsiFocus` and `scRole` on the admin payload only.
3. Regenerate the OpenAPI schemas and clients, and the cable schema and client.

### Phase 4 — Frontend
1. Display: the ship page, compare, `useModelMetricRows`, the vehicles table, the loadout and picker modals, and the landing sample payload.
2. Filters: `ModelFocusSelect` and the model, hangar and fleet filter forms, the filter summary, and a stealth toggle.
3. Slots: `useShipMatch` as "has it among its foci", plus the event and mission slot modals and cards.
4. Admin: a multi-select, the stealth toggle, and the raw RSI and game-file values under it.

### Phase 5 — Labels
1. Every key in all seven locales, by hand.

## Intent Verification

- [ ] **The focus filter lists only the vocabulary's keys**, translated.
- [ ] **`fighter` and `warship` each return every ship of their tiers or classes.**
- [ ] **`stealth` + `fighter` returns the stealth fighters without the Eclipse.**
- [ ] **An RSI or game-file sync writes only known keys** and logs unknown values.
- [ ] **A slot asking for a focus accepts a ship that has it among several.**
- [ ] **Public pages show no raw source wording**, and the admin edit page does.

## Key files

| File | Role |
|------|------|
| `app/models/model.rb` | Normaliser, filters, ransack, paper trail, sort keys |
| `app/models/{fleet_event_ship,mission_ship,vehicle,fleet_vehicle}.rb` | Slot normalisers, ransack aliases, sort fields |
| `app/lib/rsi/models_loader.rb`, `app/lib/sc_data/loader/models_loader.rb` | Source mapping |
| `app/controllers/api/v1/filters/models_controller.rb`, `admin/api/v1/models_controller.rb` | Filters and permitted params |
| `app/api_components/**` (model, queries, slot inputs) | API schema |
| `app/views/**/_base.jbuilder` (models, slots, signups) | Payloads |
| `app/frontend/frontend/composables/useShipMatch.ts` | Slot matching |

## Not in scope (deferred)

- **Dropping the old `focus` column**, with the `focus`/`modelFocus` sorts and the deprecated `focus` API fields. It needs a release after this one has deployed.
- **`Api::V1::ModelsController#focus`.** It has no route and looks dead.

## Discovery Log

- **2026-10-22** Labels are server-side (`filter.model.focus.items.*` in the Rails locales), served as `fociLabels`, so Phase 5 landed with Phase 3. `focusIn` stays a plain string array in the query schemas: typing it as the enum would 400 an old bookmarked filter.
- **2026-10-22** No backend code matches slots to ships; only `useShipMatch.ts` does. The parsed tree's roles add `Turret` and `Interceptor` to the mapping. `has_paper_trail` tracks `focus`, so the change history will show arrays.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Phase 4
- [ ] Phase 5
