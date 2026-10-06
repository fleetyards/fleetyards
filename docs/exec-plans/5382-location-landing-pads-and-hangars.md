# Locations: landing pads and hangars per station and spaceport

Working plan for #5382. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Station, city and spaceport pages list their hangars, landing pads, vehicle pads and docking collars from the exporter's `derived/landingzones.json`, and each Stanton city's spaceport is a place of its own.

## What changed

### Phase 1 — Parser
1. `StarmapParser` reads `#{base_path}/derived/landingzones.json`; a missing file means no facilities and no spaceports.
2. Join locations to places by `starmapRef` in `refs`, falling back to `starmapRecord == key`; log and skip the rest.
3. Synthesise `<city>_Spaceport` places from a city's `_sp_ext` zone; the city keeps its other zones.
4. Emit `facilities` (`hangars`, `landing_pads`, `vehicle_pads`, `docking_tubes`) on each place.
5. Spaceport names in `location_overrides.yml`; `spaceport` added to `Location::KINDS`.

### Phase 2 — ParsedCheck
1. Once any place carries facilities, the Stanton spaceports and the big stations must have hangars.

### Phase 3 — Model and loader
1. Migration: `facilities` jsonb on `location_builds` and `locations`.
2. `LocationBuild::FACTS`, `LocationsLoader#build_params`.

### Phase 4 — API
1. `facilities` on the location detail payload and schema; regenerate schema and client.

### Phase 5 — Frontend
1. A facilities card on the location page; `spaceport` kind label and icon in all 7 locales.

## Intent Verification

- [x] A station page lists its landing pads by size and its hangar count, from the game files.
- [x] Each city's spaceport is a place inside it, with the same facts.
- [x] The numbers follow each new build (a `LocationBuild` fact).

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/starmap_parser.rb` | reads the file, joins, synthesises spaceports |
| `config/sc_data/location_overrides.yml` | spaceport names |
| `app/lib/sc_data/parsed_check.rb` | facilities floor |
| `app/models/location_build.rb`, `app/lib/sc_data/loader/locations_loader.rb` | the fact |
| `app/views/api/v1/locations/show.jbuilder`, `app/api_components/v1/schemas/location.rb` | payload |
| `app/frontend/frontend/pages/locations/[slug].vue` | page |

## Not in scope (deferred)

- Nothing.

## Discovery Log

- **2026-10-07** At the start no export carried `derived/landingzones.json`; it arrived for `4.10.1-live.12660092` during the work.
- **2026-10-07** Parsed against it: 58 places with facilities, 547 hangar doors (559 less the 12 at the collector base, which has no starmap record), 233 landing + 159 vehicle pads, 108 docking tubes. Matches the exporter's totals.
- **2026-10-07** Loaded into the worktree DB and checked Everus Harbor and Teasa Spaceport in the browser.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [x] Phase 5
