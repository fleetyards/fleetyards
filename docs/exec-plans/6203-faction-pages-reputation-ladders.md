# Faction pages with reputation ladders

Working plan for #6203. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Factions, their reputation ladders and each award's ladder and outcome are parsed, loaded per build and shown on public faction pages and mission pages.

## What changed

### Phase 1 — Parser
1. `ContractsParser` adds `ladder_key`, `ladder_name` and `outcome` to reputation rewards.
2. New `FactionsParser` writes `parsed/<env>/factions/*.json`, after `ManufacturersParser` so its logos survive that parser's folder clear.
3. `ParsedCheck` gains the `factions` catalogue.

### Phase 2 — Storage
1. `factions`, `faction_builds`, `faction_ladders`; reward columns.
2. `FactionsLoader` in `BaseLoader.all`; `FactionBuild` in `CheckJob::VERSIONED_CATALOGUES`.

### Phase 3 — API
1. `GET /factions`, `GET /factions/{slug}`, components, schema.
2. Mission reward and org fields.

### Phase 4 — Frontend
1. Catalogue tenant, index and detail pages, Rails route for link previews.
2. Mission rewards show ladder and outcome; org links to the faction.
3. Every locale translated by hand.

### Phase 5 — Real data
1. Re-parse live and ptu into a scratch tree, diff against the current tree.
2. Run `test/contracts` against the scratch tree.
3. `bin/scdata push` needs the owner's go-ahead: it writes to the shared bucket.

## Intent Verification

- [ ] Foxwell's page lists `Standing` first, because its awards feed it
- [ ] Northrock does not show two identical Security ladders
- [ ] No page shows a placeholder rank or an `@` key
- [ ] Manufacturer logos are all still in the parsed tree after a re-parse
- [ ] A mission's loss on non-completion reads differently from a gain on completion

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/contracts_parser.rb` | Reward ladder and outcome |
| `app/lib/sc_data/parser/factions_parser.rb` | Faction export |
| `app/lib/sc_data/loader/factions_loader.rb` | Load per build |
| `app/models/faction.rb` | Row, read-through, award stats |
| `app/controllers/api/v1/factions_controller.rb` | Public API |
| `app/frontend/frontend/pages/factions/` | Pages |

## Discovery Log

- **2026-11-05** `save_icon` clears its folder once per parser instance, and rep logos share `ManufacturerLogos`, so faction logos must not clear it.
- **2026-11-05** The hover and wheeled racing ladders have no localisation keys in 4.10.2, so they are dropped by the unnamed-rank rule.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
