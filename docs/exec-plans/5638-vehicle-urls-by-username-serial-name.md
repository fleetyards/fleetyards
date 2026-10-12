# Address vehicle pages by username, serial and name

Working plan for #5638. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Owner vehicle pages live at `/hangar/:username/:segment/<tab>/`, where the segment carries the game serial or the UUID plus the name, and every older vehicle URL lands there.

## Open questions
- None yet.

## What changed

### Phase 1 — Serial format (backend)
1. `Vehicle::SERIAL_FORMAT = /\A[A-Z0-9]{2}-[A-Z0-9]{4}-[A-Z0-9]{2}\z/`. `normalize_serial` strips, upcases, and inserts the dashes into a bare 8-character serial (`L84261HA` → `L8-4261-HA`).
2. Format validation `if: :serial_changed?`, with a literal error code, translated in all 7 locales.
3. `Vehicle.game_serial(value)`: the normalised serial when it matches the format, otherwise `nil`. Not exposed through the API: the frontend mirrors the format in `utils/vehicleSegment.ts`.
4. `HangarImporter`: drop a serial that does not match before `Vehicle.create`, so the vehicle still imports. Add importer tests for valid, legacy and absent serials.

### Phase 2 — Reserved usernames
1. `User::RESERVED_USERNAMES` lists every static `/hangar/*` child: wishlist, preview, fleetchart, transfers, inventories, transactions, imports, buybacks, paints, flair, equipment, stats. Validate with a case-insensitive check, following `Fleet#fid_not_a_route_name` and its `route_name` message (all 7 locales).
2. Add a frontend route spec that walks the static children of `/hangar/` and fails when one is missing from the list (the list is exposed through a small shared constant or a fixture).

### Phase 3 — Segment helpers (frontend)
1. `vehicleSegment(vehicle)` (with `gameSerial`, `name` and `id`) builds `serial-name`, `uuid-name`, `serial-uuid` or `uuid`, with the name parameterized and the serial lowercased.
2. `vehicleIdentifierFromSegment(segment)` returns the UUID if the segment contains one, otherwise a leading serial (upcased), otherwise `null`.
3. `vehicleRoute(vehicle, name, username)` produces `{ name, params: { username, segment } }`. Every caller passes `sessionStore.currentUser.username`, because these are always the reader's own ships.
4. Unit specs cover all four shapes, names with punctuation and non-Latin text (parameterizing to an empty string falls back to the shape without a name), and a serial that looks like a UUID.

### Phase 4 — Routes
1. In `hangar/routes.ts`, nest the vehicle shell and its tabs under `:username/` as `:segment(<uuid-or-serial regex>)/`, plus `cargo/:item/`. The regex keeps `stats`, `wishlist` and `fleetchart` on the public hangar routes.
2. Owner guard: if `:username` is not the current user (case-insensitive), redirect to `hangar-public`, which already handles private hangars.
3. The shell page resolves `vehicleIdentifierFromSegment`, then calls `useShowVehicle(identifier)`. Once the vehicle loads, it `router.replace`s to the canonical segment when they differ. That covers renames, serial changes and old serial-plus-name links, and also catches the `NamingModal` save.
4. Legacy routes `/hangar/:id/` and `/hangar/:id/<tab>/` (including `cargo/:item/`) stay as guards. They fetch the vehicle by the old id or serial through `ensureQueryData` and redirect to the canonical route. This includes free-text serials, which `find_by_id_or_serial!` still resolves.
5. The Rails `hangar/:id/cargo/transactions` 301 stays: it lands on the legacy `/hangar/:id/cargo/` route, which now forwards to the new address.
6. `invalidateVehiclePage` keeps invalidating by both id and serial, since the cache key is still the identifier.

### Phase 5 — Call sites
1. Switch every link to the helper: OwnersList, Panel, Table, ContextMenu, the three Overview cards, the `[id].vue` breadcrumb, `inventories/index.vue` and `cargo.vue`/`cargo/[item].vue`, which today pass the UUID.
2. Move `pages/hangar/[id]*` to `pages/hangar/[username]/[segment]*`, or keep the files and change only the routes. Decide by the size of the diff.
3. Update specs: the OwnersList, Panel, Table and ContextMenu route stubs and expected hrefs, `routes.spec.ts`, and `pageKey.spec.ts` (the key moves one segment deeper).

## Intent Verification

- [ ] **Canonical URLs**: a ship with serial `L8-4261-HA` and name "USCS Tanngnjostr" links to `/hangar/<me>/l8-4261-ha-uscs-tanngnjostr/overview/`. A nameless one without a serial links to `/hangar/<me>/<uuid>/overview/`.
- [ ] **Renames redirect**: after renaming the ship, the old URL replaces itself with the new one.
- [ ] **Old links**: `/hangar/<uuid>/loadouts/`, `/hangar/L8-4261-HA/loadouts/` and `/hangar/SUB%20FLAGSHIP/loadouts/` (legacy serial) each land on the canonical loadouts tab.
- [ ] **Owner-only**: `/hangar/<someone-else>/<their-uuid>/` redirects to their public hangar.
- [ ] **Public hangar intact**: `/hangar/<user>/`, `stats/`, `wishlist/` and `fleetchart/` resolve as before.
- [ ] **Serial input**: the naming modal rejects `F-9` on change, saves `l84261ha` as `L8-4261-HA`, and still saves a rename of a vehicle whose legacy serial is untouched.
- [ ] **Import**: importing an export with a legacy serial creates the vehicle without the serial.
- [ ] **Usernames**: signing up or renaming to `stats` fails with the route-name message.

## Key files

| File | Role |
|------|------|
| `app/models/vehicle.rb` | serial normalization, format validation, `game_serial`, `find_by_id_or_serial!` |
| `app/lib/hangar_importer.rb` | creates vehicles from imports without checking the result |
| `app/models/user.rb` | username validations; add the reserved list |
| `app/models/fleet.rb` | `RESERVED_SLUGS` / `fid_not_a_route_name`, the pattern to follow |
| `app/views/api/v1/vehicles/_base.jbuilder` | vehicle payload (`gameSerial`) |
| `app/frontend/frontend/pages/hangar/routes.ts` | hangar routes, `vehicleIndexGuard` |
| `app/frontend/frontend/pages/hangar/[id].vue`, `[id]/*` | vehicle shell and tabs |
| `app/frontend/frontend/components/Vehicles/NamingModal/index.vue` | serial input |
| `app/frontend/frontend/validations/rules/` | add the serial-format rule |
| `app/frontend/frontend/composables/useVehicleMutations.ts` | `invalidateVehiclePage` |
| `config/routes/frontend_routes.rb` | view-state redirects (`hangar/:id/cargo/transactions`) |

## Not in scope (deferred)
- **Public read-only vehicle pages**: these need a public endpoint and policy. Opened as its own issue before the PR merges if still wanted.
- **Old URLs after a username change**: they redirect to the old name's public hangar and no longer reach the ship. That's rare, and tracking it would mean storing old usernames.
- **Cleaning up legacy free-text serials or moving them to a label field**: decided against for now.

## Discovery Log

- **2026-10-12** Implemented. vue-router rejects groups inside a param pattern, so the segment pattern leaves the tail loose and the page canonicalises it. `beforeEnter` does not re-run on a params-only change; acceptable because no in-app link points at another user's vehicle. A serial edit used to leave a page opened under the old serial refetching into a 404; `invalidateVehiclePage` now writes the answer into every cached copy of the vehicle.
- **2026-10-12** Initial research and plan creation. The vehicle payload carries no owner username, but every vehicle link is the reader's own ship, so the session's username is enough. `cargo.vue` and `inventories/index.vue` link by UUID, not serial. The `serialTaken` vee-validate rule exists but no form uses it. No e2e spec opens a vehicle page.

## Progress
- [x] Phase 1 — Serial format
- [x] Phase 2 — Reserved usernames
- [x] Phase 3 — Segment helpers
- [x] Phase 4 — Routes
- [x] Phase 5 — Call sites
