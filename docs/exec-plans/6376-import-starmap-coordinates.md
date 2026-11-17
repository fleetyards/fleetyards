# Import starmap coordinates for locations, systems and jump tunnels

Working plan for #6376. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Locations carry their in-system position, systems and jump tunnels live in the database, and the fleet members star map reads them from the API instead of `data/starmap.ts`.

## What changed

### Phase 1 — Parse
1. `StarmapParser` reads `derived/starmap.json` and adds `position` to each place whose ref is placed exactly once.
2. `GalaxyParser` reads `derived/galaxy.json` (plus the `systems` list of `starmap.json` for `in_game`) and writes `star_systems/` and `jump_tunnels/`.
3. `ParsedCheck` leaves the galaxy out: RSI being unreachable during an export must not block a game patch.

### Phase 2 — Store
1. Migration: `position float[]` on `locations` and `location_builds`; new `star_systems` and `jump_tunnels` tables.
2. `LocationBuild::FACTS` gains `position`; `LocationsLoader` writes it.
3. `StarSystem`, `JumpTunnel` models; `GalaxyLoader` upserts systems and replaces tunnels, and skips when the parse has none.

### Phase 3 — API
1. `position` on the `Location` schema and `_base` view.
2. `GET /api/v1/galaxy` → `Galaxy` (`StarSystem`, `JumpTunnel` components), integration test.
3. Regenerate schema and clients.

### Phase 4 — Frontend
1. `MembersStarMap` loads the galaxy query; active = `inGame`.
2. Delete `data/starmap.ts`; update the spec.

## Intent Verification

- [ ] A load of 4.10.3 LIVE gives Area18 a position near ArcCorp's
- [ ] `GET /api/v1/galaxy` returns 90 systems, 135 tunnels, Stanton/Pyro/Nyx in game
- [ ] The fleet members star map renders the same as before

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/starmap_parser.rb` | location positions |
| `app/lib/sc_data/parser/galaxy_parser.rb` | systems and tunnels |
| `app/lib/sc_data/loader/locations_loader.rb`, `galaxy_loader.rb` | DB writes |
| `app/models/location_build.rb` | fact list |
| `app/frontend/frontend/components/Fleets/MembersStarMap/index.vue` | consumer |

## Not in scope (deferred)
- **`User::STAR_SYSTEMS`** — another hardcoded system list; could read `star_systems` once it is loaded everywhere.
- **Delamar missing from 4.10.3 `starmap.json`** — exporter side.

## Discovery Log

- **2026-11-17** Join check against 4.10.3 LIVE: 705/840 shown places match by record; `pos` is already system space.
- **2026-11-17** Galaxy rows are written by the default environment's load only, so a ptu parse cannot change `in_game` on live.
- **2026-11-17** Real 4.10.3 LIVE parse: 1,173 of 1,913 places positioned (705/840 shown); 90 systems, 135 tunnels; NYX, PYRO, STANTON in game.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
