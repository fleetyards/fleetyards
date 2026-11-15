# Ship views: use the new cargo grid, door and non-editable item data in the hull holo

Working plan for #6332. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Both hull holo viewers can show the cargo grids filled with real SCU containers, the service areas, and the doors, which open and close. Built-in items are marked, with a tooltip linking to their item page. Each layer has its own toggle and animates in and out.

## Open questions

- None. All decisions are in the issue body.

## What changed

### Phase 1: Backend import and API
1. `ShipViewsImportJob`: validate `cargo_grids[]` in `flight_hardpoints.json` (position, rotation, size, scu), and validate port `hullNode`/`itemKind` when they are present.
2. Import `flight_doors.json` into a new `doors` jsonb column on `model_hardpoint_transforms` (new migration), with `Model#holo_doors`. Map it in `field_for` and dispatch `render_data` by field. Add it to the admin `ViewsFolderUpload/mapping.ts` and to the filename fixture. An export whose listing lacks the file simply has no doors. Door `kind` isn't restricted to a fixed list.
3. `loadout-preview` jbuilder and OpenAPI schemas: add `cargoGrids[]` (name, port, parentPort, position, rotation, size, dimensions, scu, minItem, stripped), `doors[]` (id, kind, position, durationS, obbClosed, parts[{part, object, keyframes}]), and add `hullNode`/`itemKind` to ports. Regenerate the orval clients.
4. Rails tests: import job (grids, doors present and absent, malformed) and the loadout-preview integration test.

### Phase 2: Layers and the animation
1. `HoloViewer`: add a `layers` model (cargo, doors, servicing areas), with toggles in `ModelLoadoutHolo` and in the loadout modal. The modal's existing servicing-areas toggle becomes one of them.
2. A shared reveal tween (opacity plus scale from the box centre, about 250 ms, eased) for boxes, containers and highlights, both in and out. With `onDemand` rendering, invalidate every frame while it runs. Respect `prefers-reduced-motion`.

### Phase 3: Cargo grids with containers
1. `loadoutPreview.ts`: map `cargoGrids` to grid boxes. A grid under a refitted or emptied module port follows the mount rule.
2. Pack each grid with `CargoGridViewer/constants.ts` (`CONTAINER_DEFS`, `tryPlaceInGrid`, SCU_UNIT 1.25), largest containers first, after moving the packer into a shared util if it is tied to the component. Draw the containers with `CONTAINER_COLORS` inside a faint grid outline, in the grid's own frame.
3. Show no SCU total (see Decisions).

### Phase 4: Doors
1. `HoloViewer/Model`: collect door nodes by `extras.kind === "door"` (doorId, part), and fall back to the `parts[].object` name. Keep each node's closed transform.
2. Play the keyframes (t 0–1 × `durationS`) as offsets from the closed transform, in both directions. Pick by raycasting `obbClosed`, toggle on click, and add "open all". The door layer toggle shows and hides the click targets; turning it off closes every door.

### Phase 5: Built-in weapons and tractor beams (detail pages only)
1. `loadoutPreview.ts`: `builtInHighlights(ports)` keeps ports with `editable: false` and a `hullNode` whose `itemKind` is `weapon`, or whose type is `TractorBeam` (or whose default item is a tractor beam). Turrets, thrusters and structure are excluded.
2. `HoloViewer/Model`: tint every hull node with that name, and pick it on hover. Only `ModelLoadoutHolo` (ship page and vehicle hero) passes them, never `LoadoutPreview`.
3. The tooltip shows the item kind, "built-in, not editable" and the `defaultItem` name; a click links to the component page.

## Intent Verification

- [ ] **Cargo:** grids filled with containers at the right place (fixture until 4.10.3; Caterpillar 14 grids / 576 SCU once live).
- [ ] **Doors:** each Prospector door (rear hatch, ladder, power bay) opens and closes smoothly; "open all" works; no doors without `flight_doors.json`.
- [ ] **Toggles:** cargo, doors and service areas toggle independently in both viewers and animate in and out.
- [ ] **Built-in items:** a thruster shows the built-in tooltip and links to its item; editable mounts behave as before.
- [ ] Older exports, which lack the new keys, still import and render.

## Key files

| File | Role |
|------|------|
| `app/jobs/sc_data/ship_views_import_job.rb` | Import and validation of the ship-view files |
| `app/lib/sc_data/ship_view_fields.rb`, `admin/components/Models/ViewsFolderUpload/mapping.ts` | Filename mapping (shared fixture) |
| `app/models/model_hardpoint_transforms.rb`, `app/models/model.rb:636-680` | Storage |
| `app/controllers/api/v1/models_controller.rb:167`, `app/views/api/v1/models/loadout_preview.jbuilder` | loadout-preview API |
| `app/api_components/v1/schemas/models/loadout_preview/*` | OpenAPI schemas |
| `app/frontend/frontend/utils/loadoutPreview.ts` | Ports to mounts and boxes |
| `app/frontend/shared/components/HoloViewer/{index.vue,Model/index.vue,boxes.ts}` | Viewer, picking, boxes |
| `app/frontend/frontend/components/CargoGridViewer/constants.ts` | Container sizes and packing |
| `app/frontend/frontend/components/Models/LoadoutHolo/index.vue` | Ship-page hull holo, tooltip |
| `app/frontend/frontend/components/Loadout/Preview/index.vue`, `Vehicles/LoadoutModal` | Loadout modal preview and toggles |

## Not in scope (deferred)

- None.

## Discovery Log

- **2026-11-15** In the 4.10.3 build, the swappable ore pods are `hardpoint_mining_pod_*` (`ore_pods`, editable). `hardpoint_stored_pod_*` are the spare racks, `uneditable` and retired since 4.10.2. The pods were missing from the editor only because of `HULL_CATEGORIES` and the frontend tab and type filters.

- **2026-11-15** The browser never reads S3: `ShipViewsImportJob` stores the exports and the frontend reads `GET /api/v1/models/:slug/loadout-preview`, so the issue's `files.json` check happens in the import listing. The hull scene isn't merged, so nodes can be found by name or extras.
- **2026-11-15** In the Prospector export, door nodes are `door_<doorId>_<part>` with `extras`, not `parts[].object`. Door kinds include hatch and side_door. Keyframes run over t 0–1, nine per part. `cargo_grids` is empty. `hullNode` repeats. The flight_doors.json file is 141 KB (mostly keyframes).

### Phase 6: Mining bags
1. `LoadoutSlots::HULL_CATEGORIES` gains `ore_pods`, so the pod slots are served, fittable and swappable.
2. The editor lists them on the Auxiliary tab, and `takesAPart` accepts an `ore_pods` slot by category. Other Container ports (cargo lifts, canister shelves) stay hidden.
3. Stowed spare pods left in the hull get the built-in "Mining bag" mark on the detail pages.

## Progress
- [x] Phase 1: backend import and API
- [x] Phase 2: layers and the animation
- [x] Phase 3: cargo grids with containers
- [x] Phase 4: doors
- [x] Phase 5: built-in items
- [x] Phase 6: mining bags
- [ ] Visual check against the Prospector export on a running server
