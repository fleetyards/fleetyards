# Vehicle overview page with a captain's log

Working plan for #4846. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`hangar/[id]` opens on an overview of the owner's ship, and has a captain's log tab where the owner keeps their own entries against it.

## Open questions
- None yet.

## What changed

### Phase 0 — Feature flag
1. Add a `vehicle_overview` entry to `config/feature_flags.yml` and regenerate the schema, which brings in `FeatureFlagName.VEHICLE_OVERVIEW`.
2. Gate the backend log and image endpoints the same way `ship_inventories_feature_concern.rb` does. On the frontend, gate the new tabs with `meta.feature` and only make overview the default redirect while the flag is on.

### Phase 1 — Overview tab
1. `pages/hangar/[id]/overview.vue`, first in `[id]/routes.ts`, so it becomes the redirect default.
2. Point the hard-coded second crumb in `pages/hangar/[id].vue:63` at the overview.
3. Show what the API already returns: model, name/serial, paint, module package, upgrades, hangar groups, `bought_via`, and the flags `flagship`, `public`, `name_visible`, plus `sale_notify` only when `wanted`. Edit through the existing vehicle update/modal flows rather than new endpoints.
4. Add `nav.json` and `title.json` keys `hangar.vehicleOverview` in all 7 locales.

### Phase 2 — Captain's log
1. Migration and model `VehicleLogEntry` (`vehicle_id` uuid FK, `user_id`, `title`, `body`, `public`, `logged_at` defaulting to now), plus `log_entries_public_default` on `vehicles`; `has_many :log_entries, dependent: :destroy` on `Vehicle`.
2. Nested routes, controller, policy, jbuilder views, and schemas modelled on vehicle loadouts (`vehicle_loadouts_controller.rb`, `vehicle_loadout_policy.rb`, `vehicles/vehicle_loadout*.rb`, `inputs/vehicle_loadout_input.rb`); `hangar:read`/`hangar:write` scopes; a public read path for public entries on publicly visible vehicles; `ValidationError` codes in all 7 locales.
3. `pages/hangar/[id]/log.vue` tab with create/edit/delete via the generated `fyApi` hooks.
4. Factory, model test, and integration tests per action in `test/integration/api/v1/`.

### Phase 3 — Uploaded image
1. `has_one_attached :image` on `Vehicle` with `validates :image, no_vector_image: true`.
2. Signed blob id `image` (`[:string, :null]`) on the vehicle update input, like `hangar_inventory_update_input.rb`.
3. Upload with `FormFileInput` + `AllowedFileTypes.IMAGE` on the overview.
4. Show it instead of the model's stock render in the owner's hangar, on `hangar/[id]`, in the public hangar, and in the ungrouped fleet vehicle list.

## Intent Verification

- [ ] **Overview is the default** — opening `/hangar/<id>/` lands on the overview, not loadouts.
- [ ] **Overview shows ownership facts** — paint, module package, upgrades, groups, acquisition, serial, and the user-set flags are all visible.
- [ ] **Log entries are the owner's** — the owner can create, edit, and delete entries; another user's token gets 403/404.
- [ ] **Log visibility** — entries are private unless toggled public or the vehicle's default is public; public entries show only where the vehicle is publicly visible.
- [ ] **Flag off changes nothing** — with the flag off, `hangar/[id]` opens on loadouts as today.
- [ ] **Image replaces the stock render** — in the hangar, on the vehicle page, in the public hangar, and in the ungrouped fleet list.
- [ ] **Image rejects SVG** — an SVG upload fails with `svg_not_supported`, as on the other user uploads.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/hangar/[id].vue` | Tab shell and breadcrumb |
| `app/frontend/frontend/pages/hangar/[id]/routes.ts` | Tab routes; first child is the default |
| `app/models/vehicle.rb` | Associations, paper_trail `only:` list |
| `app/controllers/api/v1/vehicle_loadouts_controller.rb` | Pattern for the nested log controller |
| `app/policies/vehicle_loadout_policy.rb` | Pattern for the log policy |
| `app/api_components/v1/schemas/vehicles/` | Hand-written schema components |
| `app/validators/no_vector_image_validator.rb` | SVG rejection |
| `config/feature_flags.yml` | Flag registry |

## Not in scope (deferred)
- **Change history tab** — #4845 and its follow-up.
- **Choosing one of the model's images** — #1215.

## Discovery Log

- **2026-10-12** Initial research and plan creation. `Vehicle#sale_notify` is live: `ModelOnSaleJob` filters on it with `wanted: true`. Only `User#sale_notify` was retired in #5605. The issue's "first user-uploaded image" claim is wrong: avatars, fleet logos, inventory and markdown images are user uploads, all with `no_vector_image`.

- **2026-10-12** The public hangar has no vehicle page, so public entries open in a modal from the ship's panel. The log is gated on the viewer's flag, so anonymous visitors see nothing until the flag is on for everyone.
- **2026-10-12** The vehicle edit modal only refreshed the hangar lists, so `hangar/[id]` went stale after an edit. A successful vehicle update now also invalidates the vehicle page's query, under both its id and its serial.
- **2026-10-12** The bulk delete removes log entries and purges the image along with the vehicle, since it bypasses `Vehicle#destroy`.

## Progress
- [x] Phase 0 — Feature flag
- [x] Phase 1 — Overview tab
- [x] Phase 2 — Captain's log
- [x] Phase 3 — Uploaded image
