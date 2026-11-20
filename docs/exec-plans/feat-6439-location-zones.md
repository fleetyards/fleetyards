# Armistice and restricted areas on the location card

Issue: https://github.com/fleetyards/fleetyards/issues/6439 (goal, decisions, acceptance criteria)

## Phases

- [x] Parser: read `derived/zones.json`, give each record-backed place `armistice` and `restricted_areas`
- [x] Columns on `locations` and `location_builds`, loader, API schema and view
- [x] Location stats card badges, translations in every locale
- [x] Tests: parser, loader, card spec

## Key files

- `app/lib/sc_data/parser/starmap_parser.rb` — `zone_facts`
- `app/lib/sc_data/loader/locations_loader.rb`
- `app/api_components/v1/schemas/location.rb`, `.../enums/nullable_location_armistice_enum.rb`
- `app/frontend/frontend/components/StatsCard/Location/index.vue`

## Discovery log

- 4.10.3 LIVE parse: armistice whole 85, partial 142; restricted areas on 124 places (120 Onyx facilities from the ASD labs, plus Lorville, Orison, Area18, New Babbage).
- The 5.0 PTU export `13238477` has no `zones.json`; PTU places get nil until the next export.
