# Dedication plaque for ships in your hangar

Working plan for #5637. Decisions live in the issue body. Deleted before the PR merges.

## Goal
An owner can give a hangar vehicle a dedication plaque in the style of the Star Trek and "The Only Constant" plaques, composed from vehicle, model and manufacturer data plus a few owner-written lines.

## Open questions
- None.

## What changed

### Phase 1 — Manufacturer shipyard
1. Migration: `shipyard` (string) + `shipyard_location_id` (uuid, FK to locations) on `manufacturers`; `links_location :shipyard` on `Manufacturer`.
2. Admin API: permit + schema (`app/api_components/admin/v1/schemas/...`), admin manufacturer form with the location picker.
3. Public: the shipyard name on the manufacturer payload used by vehicles.

### Phase 2 — Vehicle fields
1. Migration on `vehicles`: `dedication` (text), `launched_on` (date), `launch_port` (string) + `launch_port_location_id` (uuid), `affiliation` (string).
2. `Vehicle`: `links_location :launch_port`; length validations (`dedication` ≤ 280, `affiliation` ≤ 100); `validation_error.yml` in all 7 locales.
3. Permit in `vehicle_overview_params` (`Api::V1::VehiclesController`).
4. Owner `_base.jbuilder` always renders them; public `_base.jbuilder` only `if vehicle.public?` (fleet lists render the public partial without filtering on `.public`). Check the `_vehicle` cache keys cover the linked launch port, like `linked_location&.link_cache_key`.
5. Schemas: `Vehicle`, `VehiclePublic` (`additionalProperties: false`), `VehicleUpdateInput`; `./bin/generate-schema`, `bin/generate-asyncapi`, `bin/generate-clients`.
6. Tests: model, `vehicles_test.rb`, `public_hangars_show_test.rb` (absent on non-public), `fleets_vehicles_index_test.rb`.

### Phase 3 — Frontend
1. `Vehicles/Plaque` component: manufacturer logo, ship name, class line, registry, "Commissioned from", "Launched <Month YYYY+930>, <port>", "Captain <owner>, <affiliation>", quote. Lines without data are dropped.
2. Edit fields in a `PlaqueEditModal` opened from the card, like `LocationModal`: dedication textarea, launch date, launch port (same picker as `location`), affiliation.
3. Plaque card on `pages/hangar/[id]/overview.vue`.
4. Public: a plaque button on `Vehicles/Panel` (non-editable, `public` + dedication set) opening a `PlaqueModal`, like `PublicLogModal`.
5. Labels and texts in all 7 locales, translated by hand.
6. Specs: Plaque (in-universe year, dropped lines), Modal, Panel, overview.

## Intent Verification

- [ ] **Set, edit, clear** — every owner field round-trips through the edit modal
- [ ] **Shipyard** — an admin sets a manufacturer's shipyard and it shows on its ships' plaques
- [ ] **Overview** — the plaque shows only with a dedication; empty lines are absent
- [ ] **Year** — a 2026-10-12 launch renders "October 2956"
- [ ] **Public gating** — the public hangar opens the plaque for a public vehicle; a non-public vehicle's fields are absent from public and fleet payloads
- [ ] **API** — schemas updated and api-schema-check passes
- [ ] **Locales** — all 7 locales

## Key files

| File | Role |
|------|------|
| `app/models/concerns/linked_locations.rb` | `links_location` for shipyard and launch port |
| `app/models/{vehicle,manufacturer}.rb` | Fields + validation |
| `app/controllers/api/v1/vehicles_controller.rb` | Permitted params |
| `app/views/api/v1/vehicles/_base.jbuilder` | Owner payload |
| `app/views/api/v1/public/vehicles/_base.jbuilder` | Public/fleet payload, gated on `public?` |
| `app/api_components/v1/schemas/vehicles/{vehicle,vehicle_public}.rb` | Response schemas |
| `app/api_components/v1/schemas/inputs/vehicle_update_input.rb` | Input schema |
| `app/frontend/frontend/components/Vehicles/{Modal,Panel,PublicLogModal}/index.vue` | Edit form, public card, modal precedent |
| `app/frontend/frontend/pages/hangar/[id]/overview.vue` | Owner detail page |

## Not in scope (deferred)
- **Crew columns** — decided against (see issue).
- **Public vehicle page** — a shareable per-vehicle page; its own issue.
- **Printable plaque image** — follow-up once the design settles.

## Discovery Log

- **2026-10-12** Initial research. Template: #5632 (`model_image_id`). No public vehicle page exists; manufacturers carry no location.
- **2026-10-12** sc_data manufacturer records carry only code, name, description and icon: no location. Shipyards researched on starcitizen.tools; only Crusader (Orison) is in a system we load. RSI's "London Ship Yards" comes from CIG's own plaque on The Only Constant. Banu, Grey's Market and Vanduul have none.
- **2026-10-12** The manufacturer partial nests in the cached model payload, whose key does not move when a manufacturer changes, so the shipyard is rendered on the vehicle and the manufacturer joins the vehicle cache keys.
- **2026-10-12** `data:migrate` cannot replay from scratch; the shipyard migration was verified in a rolled-back transaction instead.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Visual check of the plaque in a running app
- [ ] Review
