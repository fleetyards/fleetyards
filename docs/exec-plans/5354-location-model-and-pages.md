# Locations: a model and pages for places, so they can be linked

Working plan for #5354. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every named starmap record exists as a `Location` with a public page, loaded from the game files and nested where it physically is, so a later `[*location:…*]` token has something to link to.

## Open questions
- **PYR6 L1 station (awaiting an in-game check)** — the Lagrange point "PYR6 L1" is named and loaded. The station `RR_P6_L1` under it has no name in any locale or build, and its children "P6 L1_Clinic" and "P6 L1_Habs" are dropped with it. The tag rule would rescue only the habs, under PYR6 L1. Is there a station there in-game, and what is it called?

## What changed

### Phase 1 — Parser
1. `SCData::Parser::StarmapParser`: read every StarMapObject record under `starmap/pu/**` (stations sit in `station/` and at the top level, not only in `system/`), resolve the type name (`starmapobjecttypes.records.xml`) and the `global.ini` name, and write `parsed/<env>/locations/*.json` (`sc_ref`, `sc_key`, `parent_ref`, `map_parent_ref`, `kind`, `name`, `description`, `system`, `shown_on_starmap`, `shown_with_parent_only`, `always_shown`, `quantum_travel_destination`).
2. Skip unnamed records: the key is missing, or its value is `<= UNINITIALIZED =>`, `<= PLACEHOLDER =>` or blank. A skipped record takes its whole subtree with it. Then fold a record into its parent when both share a name key (Vision Center, Bevic Convention Center).
3. Refine the parent from the tag database: walk up `locationHierarchyTag` to the first tag that resolves to a named record (by its own tag, or by a unique name match), and take that record only when it sits below the starmap parent. `map_parent_ref` keeps the game's own map parent.
4. Apply `config/sc_data/location_overrides.yml` (rename, drop, or merge a list of `sc_key`s into one location), drop non-places by key pattern (`_Template`, `DynamicSpawned…`, a hidden `_Sandbox` that has a `_Sandbox_001`), fold a record into a same-named parent. Drop records that end up under no system (mission markers). Place each Star under the SolarSystem with the same key prefix (`StantonStar` → `StantonSolarSystem`). Build an Ellis System location from the `Ellis`/`Ellis_Desc` keys for Green.
5. Register it in `base_parser.rb`, add a floor to `parsed_check.rb`, and add fixtures under `test/fixtures/sc_data/parsed/test/locations/`.
6. Re-parse and push the tree (~6 min).

### Phase 2 — Model + loader
1. Migration `locations`: uuid, `sc_key` (the first merged record's), with every source record's `sc_ref` in a `location_records` table (unique `sc_ref`), `slug` (unique), `name`, `description`, `kind` enum, `parent_id` (self-reference), `map_parent_id` (self-reference, the in-game map parent when it differs), `star_system`, the four star-map booleans, `retired_at`.
2. `Location` model: `KeyedSlug` (names collide), `parent`/`children`, a `listed` scope, ransackable attributes.
3. `location_builds` for per-source facts (name, parent, star-map flags), like `game_mission_builds`, so PTU-only locations show as such.
4. `SCData::Loader::LocationsLoader` (find by `sc_ref`, two passes for parents, `retire_absent`), registered in `base_loader.rb`.

### Phase 2b — Links
1. `terminals.location_id`, set during the UEX sync: take the most specific of `outpost_name`, `city_name`, `space_station_name`, `moon_name`, `planet_name` and `orbit_name`, and match it by normalised name within the terminal's star system. Strip a bracketed suffix ("Pyro Gateway (Stanton)") and a trailing " Station" ("Checkmate Station"). Break a tie on duplicates by the moon or planet named in the row, then fall back to a name prefix ("Deakins Research" → "Deakins Research Outpost"). Unmatched terminals keep `location_id` null.
2. Mission → location links, two sources. (a) Location templates: each `MissionLocationTemplate` links through its most specific location tag (owner rule as for parents), and only when the owner is a specific place, not a star, planet or moon. (b) Text mentions: whole-word, case-sensitive matches of unique location names in the mission title and description. Exclude names of markers that hang under no system ("Salvage") and names that are also common words ("Green").

### Phase 3 — Public API
1. `Api::V1::LocationsController` (index with filters on kind and system, show by slug), routes, jbuilder views.
2. Schemas `location(s)`, `location_kind_enum`, `location_query`, a sorting enum; then `bin/generate-schema` and `bin/generate-clients`.
3. Integration tests in `test/integration/`.

### Phase 4 — Frontend
1. `pages/locations/{index,[slug]}.vue` + routes, mounted at the top level under `/locations`; list/row/filter components; on the detail page, a breadcrumb up the parent chain; wherever a name is not unique (rows, links, search, token suggestions), show it with its parent ("Outpost 54 · Aberdeen"); the children listed below, and a star-map block (shown on the map or hidden, only with its parent, always shown, QT destination, and the map parent when it differs).
2. Meta tags (`frontend_routes.rb`, `Frontend::BaseController`), nav entry, labels in all seven locales.

### Phase 5 — Admin (if wanted)
1. A read-only admin index/show, like missions.

## Intent Verification

- [ ] **Locations exist** — after a load, Stanton → Hurston → Lorville is a parent chain of `Location` rows with localised names.
- [ ] **Physical nesting** — Levski's parent is Delamar (Nyx › Delamar › Levski), and its map parent is the Nyx star.
- [ ] **Star-map logic is visible** — Levski's page says it is always shown on the map at system level under Nyx; Lorville's says it only shows once Hurston is selected; a hidden clinic says it is hidden.
- [ ] **Unnamed records are skipped, subtree included** — no `Location` has a filler name, and nothing under an unnamed record is imported; Mercy Hospital exists once, under Levski.
- [ ] **PTU-only places** — a location only present in a PTU build shows as PTU-only.
- [ ] **Links** — a UEX terminal and a mission location point at their `Location`.
- [ ] **A location has a page** — `/locations/lorville` renders its name, kind, the parent breadcrumb and its children.
- [ ] **Slugs are stable and unique** — colliding names get keyed slugs, and a re-load never re-slugs an existing row.
- [ ] **Retirement** — a location dropped from the build is retired, not deleted.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/contracts_parser.rb` | Reference parser (missions) |
| `app/lib/sc_data/parser/base_parser.rb` | Parser registry, `load_data`, localisation |
| `app/lib/sc_data/loader/game_missions_loader.rb` | Reference loader |
| `app/lib/sc_data/parsed_check.rb` | Parsed-tree floors |
| `app/models/concerns/keyed_slug.rb` | Collision-safe slugs |
| `app/controllers/api/v1/game_missions_controller.rb` | Reference public controller |
| `app/api_components/shared/v1/schemas/game_mission.rb` | Reference schema |
| `app/frontend/frontend/pages/missions/` | Reference pages |
| `app/frontend/frontend/pages/missions/routes.ts` | Reference route file |
| `app/models/terminal.rb`, `app/lib/uex/terminal_syncer.rb` | String hierarchy, possible later link |

## Not in scope (deferred)
- **`[*location:…*]` tokens** — follow-up per the issue: `Catalogue::TokenResolver::CATALOGUES`, `markdown_plain_text.rb`, `CatalogueTokens.ts`, `catalogueItemRoute.ts`. Name collisions matter there.
- **Free-text `location` columns → FK** — fleet events, inventories and item prices keep their strings.
- **Mission → location links** — mission placement tags aren't linked to the starmap in the export; `locationHierarchyTag` might bridge it later.
- **Starmap rendering** — `data/starmap.ts` stays as it is.

## Discovery Log

- **2026-10-01** `Hash.from_xml` reads a dash in an element name as an underscore, so override keys take the underscore form (`RR_NYX_CASTRA_JP1_CLINIC`).
- **2026-10-01** Real-data load: 1847 locations, 784 missions linked (3144 template links, 360 text links), 157 of 161 UEX commodity terminals matched. Grim HEX's two terminals stay unlinked: UEX names the station "Green Imperial Housing Exchange", a name the starmap does not use.

- **2026-10-01** UEX terminals: of 161 commodity terminals, 153 match a location by normalised name; a name-prefix rule adds 3. The unmatched ones are Port Olisar (retired), "Admin - UEX Station" (no place), Green Imperial Housing Exchange ×2 (no starmap record), and Slowburn Depot (two identical records under Monox). The dev DB has no terminals; the measurement used the live `https://api.uexcorp.uk/2.0/terminals` feed.
- **2026-10-01** Mission locations: no template references a starmap GUID. Through tags, 854 of 2103 templates resolve to one location: 410 planets, 187 stars, 141 moons, 94 asteroids, 20 landing zones, 2 manmade. 1061 carry no location tag, and 188 are ambiguous (Pyro asteroid tags RegionA–D, shared by about 35 bases each, and Orison). Child records reuse their parent's tag, and planets carry no tag of their own, hence the owner rules. `pu_missionlocality/*.xml` (17 files) lists starmap GUIDs and is referenced by 488 contract-generator records, a second, region-level bridge.

- **2026-10-01** `parent` is the in-game map parent, not physical containment. Levski hangs from the Nyx star (`overridePermanent`, `onlyShowWhenParentSelected="0"`), while the tag database nests it under Delamar. 563 of 1899 named records have a tag. The "below the starmap parent" rule changes only Levski in 4.10.1; tags are coarser elsewhere (Pyro outposts tagged "Pyro" while their parent is Pyro I).
- **2026-10-01** 148 of 2047 records are unnamed: 66 with a missing key, 57 `UNINITIALIZED`, 16 `PLACEHOLDER` and 9 blank. `RR_P6_L1` (the Pyro VI L1 station) has no name in any locale or build from 4.9.0 to 4.10.1. 7 named records have an unnamed parent.
- **2026-10-01** The game files are the source: all 2047 `StarMapObject` records under `starmap/pu/**` (not only `system/`) cover every place checked, including Grim HEX, Levski, Ruin, Checkmate, Orbituary, Klescher, the gateways and the Lagrange stations. Each one has a GUID, a `parent` GUID and a type. Some records belong to systems that aren't playable ("Terra Gateway").
- **2026-10-01** Initial research. The raw export has the full hierarchy as `StarMapObject` records; no parser reads `starmap/` yet. Terminals come from UEX, not sc_data. Mission locations carry tags only (`parser/mission_locations.rb:37-41`).

## Progress
- [x] Phase 1 — Parser
- [x] Phase 2 — Model + loader
- [x] Phase 2b — Links
- [x] Phase 3 — Public API
- [x] Phase 4 — Frontend
- [ ] Phase 5 — Admin (not built; ask whether it is wanted)
