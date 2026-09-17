# Blueprints — a catalogue of what can be crafted, from what, and where the recipe comes from

## Goal

A public, filterable Blueprints catalogue: 1607 recipes, each linked to the thing it makes,
every resource slot with its quantity, quality gate and the stats that slot moves, and —
for the 732 that have one — the org whose missions hand the recipe out.

## Context

Resolves #4988.

Crafting has been in the game files since 4.9.0 and Fleetyards holds none of it — `grep -ri
blueprint` finds two unrelated hits. Everything below was measured against
`data/sc_data/raw/4.10.1-live.12660092`, which is the newest raw dump in the tree.

This is a loader-and-surface job, not a research job: the counts, the traps and the shape of
each record are already established in the issue body. What this plan adds is the contract
chain, which D4 pulled into scope and which the issue described but did not verify.

Related: #4989 (a public Components catalogue). Both issues want a public catalogue of
sc_data that today only exists behind the API and admin. D8 settles the shell once, here.

## Decisions

Nine decisions were open on the issue. Five are taken as the issue recommended them and are
recorded below for the record; four were put to the user and are recorded with what was
chosen and what it costs.

### D1 — A blueprint has no name; the output supplies it

1606 of 1607 records carry `blueprintName="@LOC_PLACEHOLDER"`. The single exception is a
mission item. Name, icon and manufacturer therefore all come from the crafted output.

**Amended once built.** The first wording made the output link mandatory and said a recipe
whose output does not resolve must not be loaded. That is wrong twice over, and the
implementation does neither:

- The *name* is what has to resolve, not the link. The parser reads the entity's own
  localisation as well, so the four mission carryables that are in no catalogue still load
  named. 28 recipes carry no `craftable`; all but four carry a name.
- Dropping a recipe because its output is missing would hide 23 real ones that are only
  missing because of the localisation bug in #4997, and they would come back silently the
  day that lands. They load, linked to nothing, and the loader counts them.

Four load with no name at all: `bp_craft_cool_s04_cnou_pioneer`, whose entity class is in no
file in the export, and three radars the game itself does not name. The page has to say so
rather than render a blank.

### D2 — The output is polymorphic

One blueprint points at a `Component`, an `Equipment` or a `Commodity`. Stored as a
polymorphic `craftable` association — the shape `FleetInventoryItem#item` already uses.

Rejected: three nullable FKs. That puts a three-way `COALESCE` into every list query, and a
two-table `COALESCE` expression is precisely what drops every index off a filter.

Note against a unique index: **three outputs have two blueprints each** (the 890 Jump and
Polaris S04 shields, two S01 quantum drives, two S02 powerplants). Near-certainly copy-paste
in the game data, but a unique index on `craftable` would fail the load.

### D3 — Store slots and options, render the flat case flat

The cost tree carries real structure: an outer `CraftingCost_Select` of N named slots
(`ASPECTS`, count=3), each an inner select of 1 naming the slot
(`@crafting_ui_slotname_armouredcarapace` → "Armored Carapace") and listing its
`CraftingCost_Resource` options.

Today every inner select has exactly one option, so a flat row would lose nothing *yet* — and
would lose the ability to say "any of these three" the day CIG adds a second. Two tables:
`blueprint_cost_slots` and `blueprint_cost_options`. The single-option case renders as a
plain line.

No `optionalCost` exists in any of the 1607; the parser ignores the element rather than
modelling it.

### D4 — The full chain to the org, in the first pass

**Chosen: pool → generator → org**, over pool membership alone.

The issue described this chain but did not verify it, and the verification changes the plan:
the references are **GUIDs, not names**. `grep -rl "BlueprintPool\|blueprintreward" contracts/`
returns **zero** files. The chain only resolves by ref:

```
blueprint ──> BlueprintPoolRecord.blueprintRewards[].blueprintRecord   (weighted)
BlueprintPoolRecord.__ref ──> ContractGenerator                        (by GUID, 130 of 154 pools)
ContractGenerator.factionReputation ──> FactionReputation.displayName  (@Foxwell_RepUI_Name)
```

Worked example, end to end:

| step | value |
|---|---|
| pool | `crafting/blueprintrewards/blueprintmissionpools/bp_missionreward_foxwellenforcement_ambush.xml` |
| its `__ref` | `af21edb5-3938-45ac-8a35-130e52463f44` |
| referenced by | `contracts/contractgenerator/mercenary_guild/foxwellenforcement/shipbattles/foxwellenforcement_ambush.xml` |
| its `factionReputation` | `016c2950-0292-468c-a408-a5283b52f158` |
| which resolves to | `factions/factionreputation/factionreputation_lawful_foxwellenforcement.xml`, `displayName="@Foxwell_RepUI_Name"` |

Measured: 154 pool records, **130 reachable from a contract generator**, 107 generator files
under 10 guild folders. Generators carry a localised title and description **per difficulty
tier** — `@Foxwell_ShipAmbush_{VE,E,M,H,VH,S}_title_001` — which is what makes "Eckhart
Security bounty missions, VHRT and up" expressible rather than just "Eckhart Security".

Cost this adds over the cheap option: a `ContractsParser` that does not exist, plus faction
resolution (the `FactionReputation` record set is a fourth entity, read for `displayName` and
logo only — not a Fleetyards table in this pass). This is the bulk of Phase 2.

**732 of 1608 blueprints sit in at least one pool. The other 876 have no stated source in the
export.** The page states that explicitly; it must not render an empty section, which reads
as a bug.

The 24 unreachable pools are the special ones — Wikelo, ORS, XenoThreat. They get their pool
name and no org, rather than being dropped.

### D5 — Category comes from the output, not the export

`blueprintcategorydatabase` lists 21 category refs and **not one resolves to a record anywhere
under `Data/Libs`**. The GUID can be stored (the fabricator whitelists in
`basebuilding_interactables_itemfabricator_{standard,allianceaid}.xml` key off it, so it
decides *which machine* can craft the thing) but it cannot be labelled.

Grouping and filtering use the output's own category, which we already have and which a
visitor already knows from the ships and components pages. Rejected: the blueprint's folder
path (`fpsgear/armour/combat`) — it is a second taxonomy for the same objects.

### D6 — Ship the quality ramps

**Chosen: parse, store and render.**

Every slot ramps a named stat linearly over quality 0→1000 via
`CraftingCostContext_ResultGameplayPropertyModifiers` (`modifierAtStart="0.8"
modifierAtEnd="1.2"`), against the 24 stats in `craftedproperties/`. Each resource option
also carries its own `minQuality` gate.

A page that lists only "0.2 SCU of Tungsten" answers none of the question a crafter is
actually asking. The data is already inside the record being parsed, so deferring it means a
full re-parse later — and a parser change means re-parse *and push* before loader tests see
anything, roughly 6 minutes each time.

Detail page shows min/max per stat per slot, and the `minQuality` gate per resource.

**Measured correction:** a stat is not always one range. 1007 of the 4,289 slots ramp a stat
*piecewise* -- 0.95 to 1.0 across quality 0-499, then 1.0 to 1.05 across 500-1000 -- so the
schema stores one row per segment and the figure a page shows spans them. A reader taking
one range per stat reports half the gain. There are also two ramp kinds, not one:
`_Linear` scales the stat (5,926 rows) and `_LinearIntegerAdditive` adds to it (598), and
they cannot be rendered with the same sentence.

### D7 — Build facts, like every other catalogue

`blueprints` + `blueprint_builds`, a `current_version` scope via `ScDataVersioned`,
`retire_absent` at the end of the loader run, `prune_builds`. 4.9.0 had 1598 blueprints and
4.10.0 has 1608, so drift is already real and a plain upsert would keep retired recipes
visible forever. Commodities, components and equipment all carry this pair.

### D8 — One shared catalogue shell, built here

**Chosen: a shared shell, ahead of either catalogue.**

Verified: the public frontend has `ships`, `tools`, `compare`, `fleets`, `hangar` — and **no**
commodities, components or equipment pages at all. Admin has all three. So #4988 and #4989 are
both adding the first public sc_data catalogue, and whichever lands second inherits the job of
reconciling two navigations.

Phase 4 builds the section shell and its nav once; Blueprints is its first tenant and
Components (#4989) hangs off the same one. This blocks nothing in #4989 — the shell lands on
this branch first and #4989 rebases onto it.

### D9 — Behind a feature flag

A `blueprints` entry in `config/feature_flags.yml` with a description, and the schema
regeneration that comes with it. A feature-flag addition reddens every descendant of a stack
until each is regenerated — expected, not a failure.

### D10 — Stacked PRs, four of them

**Chosen: stacked, over one PR or data-then-decide.**

A 1607-record loader plus a new public catalogue plus a new parser is not one reviewable diff.
Each PR below stands on its own. The known cost is the cascade: a squash merge of any PR in
the stack forces two force-push rounds per merge, leaf last.

### D11 — Cost rows hang off the build

`blueprints` and `blueprint_builds` carry the scalar facts (D7). The recipe itself
-- `blueprint_cost_slots`, `blueprint_cost_options`, `blueprint_cost_modifiers` -- hangs off
the **build**, and is rewritten wholesale on every load.

The first cut hung it off the blueprint, reasoning that nothing points at a cost line so
nothing has to keep resolving. Review caught what that misses: live and ptu are loaded
separately and a reader can be pointed at either, so one global recipe means whichever tree
loaded last supplies the costs for both -- live build facts rendered beside ptu materials.
The recipe is a fact of a build exactly the way the craft time is, so it is stored like one.
`prune_builds` and `retire_absent_builds` now carry the recipe away with the build it
belonged to, through the FK cascade.

Written with `insert_all!` against generated ids -- a full load is 4,289 slots, 4,289 options
and 6,524 modifiers, and taking those through ActiveRecord one at a time costs more than the
rest of the loader together -- inside one transaction, because the delete lands before the
three inserts and a failure between them would leave a readable build carrying half a
recipe.

### D12 — `localize` moves onto `BaseParser`, and the parser fix does not

`BaseParser#translate` matches a localisation key exactly, and misses every
`@crafting_ui_slotname_*` (all 73) and 24 of the 29 `@StatName_GPP_*` -- the game declares
them with a `,P` plural marker or in another case. `CommoditiesParser` has always carried
its own `,P`-stripped, downcased index for exactly this reason.

That index is lifted onto `BaseParser` as `normalized_translations` / `localize`, and
`CommoditiesParser` now builds on it. Verified byte-identical: re-parsing all 232
commodities against the refactor produced no diff at all.

**The other three parsers are left alone.** The same lookup would recover 84 equipment
records that are dropped today and 234 ship items that load nameless -- measured, and filed
as **#4997**. It rewrites the equipment and items trees, so it wants its own review and its
own re-parse rather than riding along with a new catalogue. 23 of the 1607 recipes make one
of those 84, and they load with no link until #4997 lands.

## What changed

### Phase 1 — Blueprints parser and loader (PR 1) — **done**

1. `ScData::Parser::BlueprintsParser` — one JSON per blueprint under
   `crafting/blueprints/crafting/**`: output ref, category ref, craft time, the cost tree
   with slot names, resource refs, `minQuality` and SCU quantities, and the per-slot property
   modifiers (D6).
2. Resource resolution. **Resource refs do not join on `sc_ref`** — the blueprint names a
   `ResourceType` GUID, while `Commodity#sc_ref` comes from the *crate* entity and is null for
   100 of 232 commodities, Iron included. The parser resolves the `ResourceType` record to its
   `@items_commodities_*` key and the loader joins on `sc_key`.
3. Migrations: `blueprints`, `blueprint_builds`, `blueprint_cost_slots`,
   `blueprint_cost_options`, `blueprint_cost_modifiers`. Polymorphic `craftable` (D2), **no**
   unique index on it (D2).
4. `ScData::Loader::BlueprintsLoader` — upsert on the blueprint's game ref, link the output,
   resolve each cost to a `Commodity`, write build facts, `retire_absent` + `prune_builds` (D7).
5. Register in `ScData::Parser::BaseParser.all` and `ScData::Loader::BaseLoader.all`.
6. Parser tests and loader tests against the **pushed** parsed tree. A parser change means a
   full re-parse and push first — the loader tests read the pushed tree, not a local one.

### Phase 2 — Contract sources (PR 2)

The shape, measured while Phase 1 was in review — it is one level deeper than D4 assumed:

```
ContractGenerator
└─ generators > ContractGeneratorHandler_Career[]      one per system (Stanton, Pyro)
   ├─ debugName, factionReputation                      the org
   └─ contracts > CareerContract[]                      one per difficulty variant
      ├─ minStanding / maxStanding                      the reputation band
      ├─ template, paramOverrides                       where the localised title comes from
      ├─ contractResults > difficulty > ContractDifficulty
      │     difficultyProfile (a GUID) + four descriptors: mechanicalSkill,
      │     mentalLoad, riskOfLoss, gameKnowledge
      └─ contractResults > BlueprintRewards { chance, blueprintPool }
```

So a pool is reached per **(handler, career contract)** pair, and "VHRT and up" is
`minStanding`/`maxStanding` rather than a tier label — the `difficulty` block is a profile
reference plus four prose enums, not a rank. Which of the two the page should say is a Phase 2
decision, not settled here.

1. `ScData::Parser::ContractsParser` over `contracts/contractgenerator/**` (107 files, 10
   guild folders): generator ref, its pool refs with their `chance`, `factionReputation`, the
   standing band, and the localised title.
2. Faction resolution: `factions/factionreputation/**` → `displayName` (`@*_RepUI_Name`) and
   logo path. Read-through only in this pass; no factions table.
3. Blueprint pools: `crafting/blueprintrewards/**` (154 records), with `weight` per reward.
4. `blueprint_sources` joining a blueprint to a pool, and the pool to its generator and org.
   130 of 154 pools carry an org; the other 24 carry the pool name alone.
5. Loader and tests; `retire_absent` over sources too.

### Phase 3 — Public API (PR 3)

1. `Api::V1::BlueprintsController` + `filters/`, matching the commodities/components/equipment
   shape: search by name, filter by output kind, category, required resource, known-source.
   Sortable, paginated.
2. Reverse endpoints: blueprints that **make** a given component/equipment/commodity, and
   blueprints that **consume** a given commodity.
3. Schema components are hand-written — a new jbuilder field changes no schema on its own.
4. `blueprints` flag in `config/feature_flags.yml` (D9) and schema regeneration.

### Phase 4 — The catalogue shell and the pages (PR 4)

1. The shared public catalogue section and its nav (D8), with Blueprints as first tenant.
   Route `meta.title` needs both namespaces: `nav.*` for the tab, `title.*` for the document.
2. `/blueprints` list — search, the four filters, sort, pagination.
3. Blueprint detail — what it makes (linked into that catalogue), craft time, every slot with
   its resource, `minQuality`, quantity, and the stats that slot moves (D6).
4. "No known source" stated explicitly on the 876 (D4).
5. All seven locales by hand — there is no Crowdin, and an en-only key reaches nobody.

**What it loads**, measured against `4.10.1-live.12660092` with the other catalogues loaded:

| | |
|---|---|
| blueprints | 1607 |
| linked to an output | 1579 — 1103 `Equipment`, 476 `Component` |
| unlinked | 28 — 23 awaiting #4997, 4 mission carryables in no catalogue, 1 entity in no file |
| nameless | 4 — the unresolved cooler, and three radars the game itself does not name |
| cost slots / options / modifiers | 4,289 / 4,289 / 6,524 |
| options resolving to no commodity | **0**, across 37 distinct materials |
| outputs carrying two recipes | 3, as predicted |

Three corrections to the issue body came out of building it:

1. **The four mission carryables are not commodities.** They are named `@item_Name_*` and
   `@mission_item_*`, not `@items_commodities_*`, so `CommoditiesParser` never sees them and
   there is no row to link. They load named -- "Probe", two "Metamaterial Test" samples, the
   TH-01 Propulsor -- from the entity's own localisation, with no `craftable`.
2. **The outer slot count is not always 3.** 62 recipes take one slot, 442 two, 1072 three,
   31 four. Stored per blueprint rather than assumed.
3. **Slot labels do resolve** -- the issue's `@crafting_ui_slotname_armouredcarapace` →
   "Armored Carapace" is right, but only through the `,P`-stripped index (D12). An exact
   lookup returns nothing for all 73.

## Intent Verification

- [x] **Parser** — `BlueprintsParser` writes one JSON per blueprint with output ref, category ref, craft time, the cost tree with slot names, resource refs, min quality, SCU quantities and per-slot property modifiers
- [x] **Loader** — `BlueprintsLoader` upserts on the game ref, links the output to its `Component`/`Equipment`/`Commodity`, resolves each cost to a `Commodity`, writes build facts and ends with `retire_absent`
- [x] **Registered and tested** — both appear in `BaseParser.all` / `BaseLoader.all` and are covered by parser and loader tests against the pushed parsed tree
- [ ] **List** — `/blueprints` searches by name and filters by output kind, category, required resource and whether a source is known; sortable and paginated
- [ ] **Detail** — shows what it makes (linked), craft time, every slot with resource, min quality and quantity, and the stats each slot moves
- [ ] **Reverse links** — a component, equipment or commodity page says which blueprints make it and which consume it
- [ ] **Sourceless blueprints say so** — the 876 with no pool render an explicit statement, not an empty section
- [ ] **API** — public endpoints and filters in the schema, matching the commodities/components/equipment shape
- [ ] **Flagged** — everything behind the `blueprints` feature flag

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/base_parser.rb` | `self.all` — register `BlueprintsParser`, `ContractsParser` |
| `app/lib/sc_data/parser/commodities_parser.rb` | Reads `carryables`; the 11 item ingredients already pass through it |
| `app/lib/sc_data/loader/base_loader.rb` | `self.all`, `retire_absent`, `retire_absent_builds`, `prune_builds` |
| `app/lib/sc_data/loader/commodities_loader.rb` | The build-fact + retire pattern to copy |
| `app/models/concerns/sc_data_versioned.rb` | `current_version` scope; `ransackable_scopes` stays per-model |
| `app/models/commodity.rb` | `sc_key` unique, `sc_ref` nullable — the join target for resources |
| `app/models/commodity_build.rb` | The build-fact model shape |
| `config/feature_flags.yml` | The `blueprints` flag (D9) |
| `app/frontend/frontend/pages/routes.ts` | Public routes — no catalogue section exists yet (D8) |
| `data/sc_data/raw/4.10.1-live.12660092/Data/Libs/Foundry/Records/crafting/` | 1607 blueprints, 154 pools, 24 crafted properties |
| `data/sc_data/raw/…/Records/contracts/contractgenerator/` | 107 generators, 10 guilds (Phase 2) |
| `data/sc_data/raw/…/Records/factions/factionreputation/` | `displayName` for the org name (Phase 2) |

## Not in scope (deferred)

- **A `Faction` table** — Phase 2 reads `FactionReputation.displayName` through to the source row. Orgs as first-class Fleetyards records is its own issue.
- **Dismantling** — `globalgenericdismantle.xml` is one global rule (efficiency 0.5, 15s), not a recipe. Nothing to catalogue.
- **Category labels** — 21 category refs resolve to nothing (D5). Revisit if CIG ships the records.
- **Fabricator machines** — the two `itemfabricator` whitelists are stored-but-unsurfaced; "which machine crafts this" is a follow-up.
- **Quality distribution / quantization** — `qualitydistribution/` (22) and `qualityquantization/` (63) describe how a resource's quality *rolls*. The ramps ship (D6); the roll model does not.

## Discovery Log

- **2026-09-17** Issue read, branch and worktree created, D1–D9 resolved with the user (D4 full chain, D6 ship ramps, D8 shared shell, D10 stacked PRs).
- **2026-09-17** Verified the contract chain against `4.10.1-live.12660092`: pool→generator references are **GUID-only** (a name grep returns zero files), 130 of 154 pools reach a generator, 107 generator files across 10 guilds, and `factionReputation` resolves to a `FactionReputation` record carrying `displayName`. Worked example recorded in D4.
- **2026-09-17** Confirmed the public frontend has no commodities/components/equipment pages at all — D8 is a real fork, not a tidy-up.
- **2026-09-17** Review on #4998 caught that the recipe was global while the build facts were per-source -- a ptu load would have overwritten the live recipe. Moved onto the build (D11), wrapped the rewrite in a transaction, and made an unrecognised ramp kind report itself.
- **2026-09-17** Phase 1 built and measured end to end against a locally loaded catalogue: 1607 blueprints, 1579 linked, 0 cost options unresolved. Found the `,P` localisation trap (D12) and filed the parser half of it as #4997; found piecewise ramps (D6) and the variable slot count.

## Progress

- [x] Phase 1 — Blueprints parser and loader (PR 1)
- [ ] Phase 2 — Contract sources (PR 2)
- [ ] Phase 3 — Public API (PR 3)
- [ ] Phase 4 — Catalogue shell and pages (PR 4)
