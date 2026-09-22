# Missions — a public catalogue of the contracts the game offers

## Goal

`/catalogue/missions/` lists every contract in the served build — 2,536 of them — with who offers it, the standing it takes, its difficulty and the rewards the export actually states, and a page per mission that links back to the blueprints it drops.

## Context

The contract-generator tree is the one part of `sc_data` we already walk and then discard. `ScData::Parser::ContractsParser` reads all 107 generators, resolves each contract's localised title, its org and its standing band, and keeps none of it as an entity — it exists only to answer "where does this blueprint come from", and writes `blueprint_pools`. 786 of the 2,536 contracts survive that walk as denormalised strings on `blueprint_sources`; the other 1,750 are thrown away.

This turns that walk into a catalogue of its own, as the fourth tenant of the `/catalogue/` section #4989 built.

### Issue lifecycle

Three PRs, not four. Phases 1 and 2 ship together: a parser with no loader reads a folder nothing consumes, and neither has a user-visible surface, so splitting them buys a review of half a mechanism and costs a stack rebase. Phase 3 (API) and Phase 4 (frontend) follow as their own PRs.

**Only the last PR carries `Closes #5125`** — the others say `Part of #5125`, so the issue survives until the tenant is actually reachable. The issue sits at **In Progress** on the Fleetyards project board (ProjectV2 #3) from Phase 1, moves to **In review** when the final PR opens, and closes on its merge.

## Decisions

### D1 — One row per contract

All 2,536 contracts are rows, and all 2,536 are list rows. Every contract carries a unique GUID in the export (2,536 distinct, zero duplicates), so identity is the export's own.

The list is 51 pages and four-fifths near-duplicate titles — "Salvager Needed (Med. Supply of RMC)" appears once per system, once per difficulty. **No grouping layer is built.** The filters (org, standing, difficulty, reward kind) are what make the list navigable, and a grouped list would have needed its own identity, its own slug and its own variants table for a reading benefit that filters already give.

### D2 — `GameMission`, not `Contract`

`GameMission` + `GameMissionBuild`; `/catalogue/missions/`, `/api/v1/missions`, admin `/missions/`.

`Contract` is unavailable in practice, not just in theory: `config/routes/api/fleets_routes.rb:85` mounts `resources :fleet_contracts, path: "contracts"`, and orval has already generated `app/frontend/services/fyApi/services/contracts/` from it. A second "contracts" tag would collide in the generated client. `Mission` is the fleet mission planner.

The prefix is not a house style — `Blueprint`, `Commodity`, `Component` and `Equipment` all come from the same parser unprefixed. It is here only to clear the fleet planner.

### D3 — No aUEC payout

The export states a payout for **8 of 2,536** contracts. 2,352 carry `ContractResult_CalculatedReward`, an empty element whose amount the game computes at runtime; there is no payout table, no currency-per-difficulty curve and no scalar anywhere in the tree.

So the catalogue leads with what the files do state — reputation amount and org, items, badges, blueprints — and the 8 explicit figures render on their own detail pages and nowhere else. No list column, no admin curation, no community sync.

### D4 — The parser is extended, not duplicated

`ContractsParser` already does the expensive half: 107 generator files, the handler walk, the faction and standing indexes. A second parser would repeat all of it to read the same records.

So `ContractsParser` gains a second output folder, `game_missions`, alongside `blueprint_pools`, and `#all` writes both from one walk. The class comment has to change with it — it currently says the file is about blueprint provenance, and that stops being true.

### D5 — The stable key

`sc_ref` is the contract GUID — unique across all 2,536, and what `blueprint_sources` will eventually point at.

`sc_key` is `"#{generator_key}_#{debug_name}".downcase`, which gives 2,520 distinct for the 2,533 contracts that have a `debugName`. No `/`: `ParsedCheck` globs a catalogue folder flat (`root.join(folder, "*.json")`) while the loader globs `**/*.json`, so a nested file would load fine and count as zero against the floor.

The 13 colliding pairs take the first 8 characters of the GUID, not a positional counter — `Dir.glob` fixes no order between builds, and a counter would swap the two contracts' history the first time it moved. The 3 contracts with no `debugName` fall back to the GUID whole. The slug generates from `sc_key`, never from the name — 902 titles carry a runtime placeholder and 45 titles are used by more than one org.

### D6 — Placeholders are rendered, not stripped

902 of 2,472 titles and 2,344 of 2,475 descriptions carry a `~mission(Location|Address)`-style span the game fills in at runtime. They reach the public API today through `blueprint_sources.mission_name`.

Deleting them breaks the sentence ("head on over to , destroy a few things"), so the parser keeps the raw string and the frontend renders each span as a muted inline token carrying the parameter name — `Location`, `TargetName`, `Ship`. One renderer, used by the mission page and by the existing blueprint sources list, which fixes those too.

The same renderer has a second job: the descriptions carry the game's own emphasis markup, `<EM4>…</EM4>`, 3,567 times across the localisation file — and 4 of those opens never close. Rendered as text it is noise; passed through as HTML it is an injection surface. It becomes emphasis or it goes, and either way it is decided in one place.

### D7 — "Currently in game" is three gates, and only one is new

The build gate (`current_version` off `ScDataVersioned`) and retirement are the standard pattern. On top of it the build carries `released` — false when the contract is flagged `notForRelease` (348) or `workInProgress` (21). The public list and the public detail page both apply `released`; admin shows everything.

One predicate, applied in both places, or a link reaches a page the list refuses to show.

### D8 — `blueprint_sources` is not touched in this issue

The normalisation — `blueprint_sources` losing its six contract columns in favour of a foreign key — is real (roughly 8,472 rows holding copies of 313 mission names) but it is a migration against a live table, it has to answer what happens to the 25 `kind: "scenario"` rows that have no contract behind them, and it needs the FK-target question (stable row vs build row) settled. It is deferred to its own issue, and this plan only adds the column the join will later need.

## What changed

### Phase 1 — Parser

1. `ContractsParser#all` writes a second folder, `game_missions`, one JSON per contract.
2. Each record carries: `sc_ref` (the contract GUID), `sc_key` (D5), `kind` (`career`/`contract`), `title`, `description` (raw, placeholders intact), `org_ref`, `org_key`, `org_name`, `org_lawful`, `generator_key`, `debug_name`, `min_standing`, `max_standing`, `released`, `difficulty` (profile key + the four ordinal bands), and `rewards` — reputation (amount + org), items, badges, blueprint pool refs, and the explicit `contractReward` where one exists.
3. The pool-source walk keeps emitting `blueprint_pools` unchanged; both outputs come from the one walk.
4. Register the new folder in `ScData::Parser::ParsedCheck::CATALOGUES` with a floor.
5. `test/parsers/sc_data/contracts_parser_test.rb` grows cases for the new output.

### Phase 2 — Model and loader

1. Migrations: `game_missions` (uuid pk, `sc_ref`/`sc_key`/`slug` unique, nullable indexed `version`) and `game_mission_builds` (cascade FK, `environment`/`version` not null, unique on `[game_mission_id, environment, version]`), plus `game_mission_rewards` hung off the build with a cascade FK.
2. `GameMission` + `GameMissionBuild` on the `ScDataVersioned` pattern: `FACTS`, `READ_THROUGH`, `FILTERABLE`, `current_facts_join`, `all_facts_join`, `fact_sql`, ransackers, `readable_builds`, sorting allowlists, `SlugConcern` off `sc_key`.
3. `GameMissionsLoader` — `load_items`, `one()` per record in a transaction, `retire_absent` + `retire_absent_builds` + `prune_builds`.
4. Registries: `BaseLoader.all`, `ScData::Source::BUILDS`, `ScData::CheckJob::VERSIONED_CATALOGUES`.
5. Loader and model tests; factories.

### Phase 3 — API

1. `config/routes/api/game_missions_routes.rb` (`resources :missions`, `param: :slug`) + the `draw` line in `v1_routes.rb`, plus a `namespace :filters` block for orgs, standings and difficulty.
2. `Api::V1::MissionsController` and `Api::V1::Filters::MissionsController`.
3. jbuilder views — `_base`, `_game_mission` (cache key including the build and the source), `_reward`, `index`, `show`.
4. API components: response schemas, the `q` query schema, the sorting enum, and enums for reward kind, alignment and difficulty band.
5. `GameMissionPolicy`; admin policy and the `RESOURCE_ACCESS[:ship_data]` entry.
6. Integration tests declaring the OpenAPI paths; `bin/generate-schema` and commit the regenerated `swagger/` + clients.

### Phase 4 — Frontend

1. `pages/missions.vue` + `pages/missions/{routes.ts,index.vue,[slug].vue}`.
2. `CATALOGUE_TENANTS` entry — this is what adds the route tree, the nav tab and active matching at once.
3. `components/Missions/{List,Row,FilterForm,Rewards}`, on the shared `RowList`.
4. `useMissionFilters.ts` (with `LIST_PARAMS`) and `useMissionSortFields.ts` (a subset of `ALLOWED_SORTING_PARAMS`).
5. The placeholder renderer (D6), used by the mission page and by the existing `Blueprints/Sources` list.
6. `config/routes/frontend_routes.rb` + a `Frontend::BaseController#mission` action for meta tags — blueprints skipped this and its detail pages render the generic site description on a shared link.
7. Admin: `admin/pages/missions/`, the `admin/pages/routes.ts` block, the Ship Data `paths` array in the admin nav.
8. Locales: `nav.catalogue.missions`, `labels.mission.*`, `headlines`, `title`, and the `filter.game_mission.*` Rails block — all seven locale files, by hand.

## Intent Verification

- [ ] **Every contract is reachable** — 2,536 rows load from the served build; the list paginates through all of them
- [ ] **A contract the build drops is retired, not deleted** — its row survives with a null `version`, its build row is gone, and it stops appearing in the list
- [ ] **One predicate** — a mission the list will not show is a mission whose detail page 404s (D7)
- [ ] **Rewards are what the files state** — reputation amount and org, items, badges, blueprints; no empty payout column anywhere (D3)
- [ ] **Blueprints link both ways** — a mission page names the recipes it drops; a blueprint page still names its missions
- [ ] **No raw `~mission(…)` on any page** — including the existing blueprint sources list (D6)
- [ ] **Missions is a catalogue tab** — and the tab only exists once the pages do
- [ ] **Labels in all seven locales** — no key falls back to `humanize`
- [ ] `bin/generate-schema` leaves a clean diff; `api-schema-breaking` passes

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/contracts_parser.rb` | Extended to write `game_missions` (D4) |
| `app/lib/sc_data/parsed_check.rb` | `CATALOGUES` — folder + floor |
| `app/lib/sc_data/loader/base_loader.rb` | `self.all` — loader registry, order matters |
| `app/lib/sc_data/source.rb` | `BUILDS` — must list `GameMissionBuild` |
| `app/jobs/sc_data/check_job.rb` | `VERSIONED_CATALOGUES` — the silent one; an absent build model is never coverage-checked |
| `app/models/concerns/sc_data_versioned.rb` | The build/fact contract the new pair implements |
| `app/models/blueprint.rb` / `blueprint_build.rb` | The reference implementation of that contract |
| `config/routes/api/v1_routes.rb` | `draw` line for the new routes file |
| `app/frontend/frontend/pages/catalogue/tenants.ts` | `CATALOGUE_TENANTS` — route tree, nav tab and active matching |
| `app/frontend/admin/pages/routes.ts`, `admin/components/Navigation/index.vue` | Admin route block + Ship Data paths |
| `app/models/admin_user.rb` | `RESOURCE_ACCESS[:ship_data]` — enforced by `AdminUserPrivilegesTest` |
| `config/routes/frontend_routes.rb`, `app/controllers/frontend/base_controller.rb` | Meta-tag route + action |

## Not in scope (deferred)

- **Normalising `blueprint_sources`** — its own issue (D8)
- **aUEC payouts** — not in the export (D3); nothing to defer *to* until a source exists
- **`contracts/contracttemplates`** — 486 files carrying objectives, deadlines and partial-reward multipliers, read by nothing today and not read here either
- **Mission locations and systems as structured data** — `MissionPropertyValue_Location` resolves through resource tags, which is a walk of its own
- **The XenoThreat scenario as a mission** — it is not a contract; the 25 `kind: "scenario"` blueprint sources stay as they are

## Discovery Log

- **2026-09-21** Survey of `live 4.10.1-live.12660092`: 2,536 contracts across 107 generators / 272 handlers; 2,472 with a resolving title (836 distinct, 902 carrying a placeholder); 2,475 resolving descriptions of which only 131 are literal; 8 explicit payouts against 2,352 `CalculatedReward`; 2,226 reputation awards, 333 item awards, 786 blueprint-pool contracts; 25 named orgs with 362 contracts unattributed. Contract GUIDs are unique (2,536/2,536); `generator/debugName` gives 2,520 distinct with 13 collisions and 3 absent.
- **2026-09-21** D1, D2 and D3 answered and recorded in the issue body.
- **2026-09-21** Phase 1 written against the real export, which caught two things the shape of the tree does not advertise. A `debugName` is free text — 64 carry a space, bracket, dash or slash, and the slash wrote a key into a directory `save_items` never created. And `<difficulty>` hangs off `contractResults` at variable depth rather than off the contract, so digging at a fixed path found none of the 2,360.
- **2026-09-21** Reading contracts only from a handler's `contracts` key missed 23 filed under `introContracts` and `PVPBountyContract` — an org's first mission among them. Five of the 23 hand out a blueprint, so fixing it also adds five contracts to the existing `blueprint_pools` output; the next load will write new `blueprint_sources` rows for them.
- **2026-09-21** `bin/scdata` requires `source.rb` directly rather than through the autoload chain, so `BUILDS` resolved its models with the class body — which worked only for models an earlier step had already loaded. Adding `GameMissionBuild` raised `uninitialized constant` before the tree check could read a file. The list is a method now, the way `BlueprintsLoader.cost_models` is.
- **2026-09-21** Both trees re-parsed (live 6m54s) and checked: `game_missions 2536 files`, no problems. The loader test loads all 2,536 against the real tree in ~87s, in line with the blueprint suite.

## Progress

- [x] Phase 1 — Parser
- [x] Phase 2 — Model and loader
- [ ] Phase 3 — API
- [ ] Phase 4 — Frontend
