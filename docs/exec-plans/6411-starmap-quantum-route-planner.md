# Starmap: plan quantum routes with a ship's stock or loadout drive

Working plan for #6411. Decisions live in the issue body. Deleted before the PR merges.

## Goal
On `/starmap`, pick a ship (stock drive or a loadout's drive), a start and a destination, and see the fastest unobstructed quantum route drawn on the map with per-leg distance, time and fuel.

## Open questions
- **Refuel stops:** the location data has no quantum-refuel service. Today a route that needs more than one tank is flagged; adding refuel stops needs station landing services parsed from the game files.

## What changed

### Phase 1 — Route maths (pure, tested)
1. `frontend/utils/quantumRoute.ts`:
   - `segmentClearsBody(a, b, body, margin)`: the shortest distance from the segment to the body's centre must exceed radius + margin. The start and end bodies are allowed when the leg leaves or lands on them.
   - `buildRouteGraph(places, drive)`:
     - Nodes are `quantumTravelDestination` places plus the start and the destination.
     - Edges must clear every body and stay within `jumpRange`.
   - `planRoute(graph, from, to)`: Dijkstra, where each leg's weight is `spoolUpTime` + travel time (`calculateTravelTime` via `quantumDriveTravelTime`).
   - `legFuel(drive, metres)`: `quantumFuelConsumption * Gm / 1000` SCU, the same convention as `pages/tools/travel-times.vue:164-184`.
   - Route totals, with a flag when total fuel exceeds `quantumFuelTankSize`.
2. Specs in `frontend/utils/quantumRoute.spec.ts`, with a `place()` factory like `Starmap/layout.spec.ts:9-33`:
   - an obstructed leg detours via a waypoint
   - an out-of-range leg is split
   - no route exists
   - fuel and time totals

### Phase 2 — Drive sources
1. Extract `findQuantumDrive` from `components/Compare/sections/model.ts:357-375` into a shared util, and use it from Compare.
2. `useRouteDrive` composable:
   - **stock:** `useModelHardpoints(slug, { source: GAME_FILES })` + `findQuantumDrive`, with the tank from `model.metrics.quantumFuelTankSize`.
   - **loadout:** `useVehicleLoadouts(vehicleId)` → `useLoadoutFitting(...)` → `findQuantumDrive`.
     - A `link` loadout or an empty slot falls back to stock and says so.

### Phase 3 — Across systems
1. Build a system graph from `useLocationJumpPoints()`: `systemId` → `destinationSystemId`, with temporary tunnels allowed.
2. For a destination in another system:
   - find the system path with BFS
   - fetch `useLocationStarmap` for each system on it
   - pair each jump-point place with its counterpart in the next system through `LocationJumpPoint.location.id`
   - give the tunnel transit a fixed cost
   - plan the legs within each system and join them.
3. Cover the pairing and joining with specs.

### Phase 4 — Starmap UI
1. **Route mode in the rail** (index.vue:522-579). Mode toggle versus the place tree in `Panel.vue`, with:
   - ship/drive picker
   - start and destination pickers (search, plus "use focused place")
   - leg list (from → to, distance in Gm, time, fuel)
   - totals and the fuel warning.
2. **`route` prop on `Scene.vue`:**
   - Its own group under `world` (like `selection`, :182), with its own watch, so `disposeBodies()` leaves it alone.
   - Leg lines built with the `line()` helper style (Line2), with their materials added to the per-frame resolution update (:1418-1419).
   - Waypoints placed via `toScene` (layout.ts:130-138).
   - Waypoints inside a folded place map to the item they fold into.
3. Keep the route in the URL (`?from=&to=&ship=&loadout=`), as `?focus=` is kept today.
4. Translations: a new `starmap.route.*` key set in every locale, written by hand.

### Phase 5 — Verify
- Plan known trips (for example Port Olisar → ArcCorp, a cross-system trip through Pyro), compare them with in-game times and routes, and tune the margin.
- Screenshots of the route on the map and the panel for the PR, with hangar names masked.

## Intent Verification

- [ ] **Drive choice**: a ship's stock drive and a `fleetyards` loadout's drive both produce a route. A `link` loadout falls back to the stock drive and shows that it did.
- [ ] **Unobstructed**: no leg of a returned route passes within radius + margin of a star, planet or moon.
- [ ] **Leg figures**: each leg lists distance, time and fuel, and the totals match the sum of the legs.
- [ ] **Fuel**: a route that needs more fuel than the tank holds is flagged.
- [ ] **Cross-system**: a route into another system goes through a jump tunnel.
- [ ] **Map**: the route is drawn on the 3D starmap and survives camera moves and changing the focused place.
- [ ] **Locales**: every new key exists in all locales.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/utils/travelTimes.ts` | Travel-time maths reused for each leg |
| `app/frontend/frontend/pages/tools/travel-times.vue` | Existing fuel convention (mSCU/Gm) |
| `app/frontend/frontend/components/Starmap/index.vue` | Data fetching, rail, URL state |
| `app/frontend/frontend/components/Starmap/Scene.vue` | 3D scene; route overlay goes here |
| `app/frontend/frontend/components/Starmap/Panel.vue` | Rail panel; route mode goes here |
| `app/frontend/frontend/components/Starmap/layout.ts` | `toScene`, folding of places, items |
| `app/frontend/frontend/components/Compare/sections/model.ts` | `findQuantumDrive` to extract |
| `app/frontend/frontend/composables/useLoadoutFitting.ts` | Resolves a loadout's fitted components |
| `app/api_components/v1/schemas/location_starmap_place.rb` | Place position/radius contract |

## Not in scope (deferred)
- **Refuel stops**: blocked on location refuel data (see open questions). Becomes its own issue before the PR merges if it is not built here.

## Discovery Log

- **2026-11-19** Live data: `jumpRange` is the float maximum on every drive; calibration is near-identical across drives; in Stanton every outpost, station and body is a quantum destination; surface places sit at 0.99–1.05 radii, the closest stations at 1.1. A* with the straight-line jump time as the estimate brings a Stanton plan from ~300 ms to ~10 ms. Link-kind loadouts are not offered as drives rather than falling back.
- **2026-11-19** Initial research and plan creation. `quantumTravelDestination` is not used anywhere in the starmap code yet. Inside a system, `links` is empty; jump points are places with `kind === JUMP_POINT`. No endpoint returns all of a user's loadouts; each hangar vehicle carries its `active_loadout`.

## Progress
- [x] Phase 1 — Route maths
- [x] Phase 2 — Drive sources
- [x] Phase 3 — Across systems
- [x] Phase 4 — Starmap UI
- [ ] Phase 5 — Verify
