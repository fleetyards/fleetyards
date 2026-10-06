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

- [ ] A station page lists its landing pads by size and its hangar count, from the game files.
- [ ] Each city's spaceport is a place inside it, with the same facts.
- [ ] The numbers follow each new build (a `LocationBuild` fact).

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

- **Checking against a real export** — no export in the bucket carries `derived/landingzones.json` yet; the exporter change is not merged. Built against a fixture of the documented shape.

## Discovery Log

- **2026-10-07** No export in S3 carries `derived/landingzones.json` (only `groundvehicles.json`, 4.9.0 onwards).

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
