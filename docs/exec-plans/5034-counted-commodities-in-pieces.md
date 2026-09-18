# Counted commodities: an inventory cannot record gems in pieces

## Goal
Eleven crafting commodities the game counts in pieces can be recorded in `units` in an
inventory, so a blueprint slot asking for 170 pieces can be compared with what a reader
actually holds.

## Context

`InventoryLedgerEntry::UNITS_BY_CATEGORY` maps `"commodity" => ["scu"]`, so every commodity
position is bulk. But a recipe states a slot's cost two ways, and the parser already keeps
them apart as `BlueprintCostOption#cost_type`:

| cost kind | quantity read from | measured in |
|---|---|---|
| `CraftingCost_Resource` | `quantity.SStandardCargoUnit.standardCargoUnits` | SCU |
| `CraftingCost_Item` | a bare `quantity` | pieces |

`useMaterialStock.forCommodity` therefore refuses to claim sufficiency for the counted kind
(`comparable = costType === BULK_COST_TYPE`) rather than inventing one. That gap is what this
issue closes.

Measured over all 4,289 cost options in `4.10.1-live.12660092`: **26 commodities are always
bulk, 11 are always counted, none is used both ways** — so the unit is a property of the
commodity, not of the slot. `commodity_type` does not predict it (minerals split 9 counted /
10 bulk).

The eleven: Hadanite · Dolivine · Aphorite · Sadaryx · Beradom · Glacosite · Feynmaline ·
Janalite · Carinite · Saldynium (Ore) · Yormandi Eye.

Resolves #5034

Follows #4988 / #5031, where this is recorded as phase 5.

## Decisions

### D1 — Read `generateRandomQuality` off the commodity's `ResourceContainer`

Of the 31 crafting commodities whose entity matches by purchasable key, every one with
`generateRandomQuality="1"` is counted (11/11) and every one without is bulk (20/20) — no
crossover. The 6 unmatched are bulk by arithmetic (26 total, 20 matched); their crates carry
no `SCItemPurchasableParams` commodity key and are named from the resource-type database
instead, so they fall through to the default of bulk.

Rejected: keying off `SMicroCargoUnit` capacity, `mutabilityLevel`, or the entity path. All
three correlate perfectly on this build, but they are consequences of the same fact rather
than the fact itself. `generateRandomQuality` is the meaningful one — the counted materials
are exactly those whose pieces each roll their own quality, which is why crafting counts them
and why the quality ramp applies per piece at all.

Rejected: deriving it from `BlueprintCostOption#cost_type`. It would be circular (the
catalogue would only know about commodities some recipe consumes), and an inventory has to
answer for all 232 commodities, not the 37 the recipes ask for.

### D2 — A build-fact boolean on `commodities`, layered like the other three

`CommodityBuild::FACTS` becomes `%i[name commodity_type description counted]`, with the
column added to both `commodities` and `commodity_builds` and the fact read through the
build. The layering is already in place from #4988's backfill; this widens it by one column.

`counted` is `null`-able on both tables and `false`-ish means bulk: rows loaded before this
lands carry no opinion, and the loader writes the fact on the next load.

### D3 — Widen `UNITS_BY_CATEGORY`, never flip it

`"commodity"` offers `["scu", "units"]` for a **counted** commodity and stays `["scu"]`
otherwise. Every existing row is SCU and stays valid — flipping the counted eleven to
`units`-only would invalidate holdings people have already written down.

The pairing is validated per entry (`unit_fits_category`), and the entry may or may not point
at a `Commodity` (`item_id` is optional, the name is free text). So: a free-text commodity
position keeps the SCU-only rule, and only an entry whose `item` is a counted commodity may
be `units`. That means the validation has to reach the item, which is a widening of
`InventoryLedgerEntry#unit_fits_category` rather than a table edit.

### D4 — A re-parse is its own step

The parsed tree in S3 is keyed by version, and the nightly loader keys on the same version,
so re-parsing `4.10.1-live.12660092` in place is invisible to both. The parser change lands
first, then the tree is re-parsed and loaded by hand.

### D5 — Off `main`; the slot check is a follow-up

Scope item 4 — making the slot's capacity check exact — touches
`app/frontend/frontend/composables/useMaterialStock.ts`, which exists only on
`feat/4988-blueprints-pages` (#5031, open at the time of writing). Phases 1–3 are
independent of it.

So this branch stays on `origin/main` and carries phases 1–3 and 5. The slot check goes in
its own change once #5031 merges. Stacking on #5031 was rejected: it would put this PR's
base on a feature branch, cascade a force-push on every #5031 update, and make
`api-schema-breaking` diff a stack against `main`.

## What changed

### Phase 1 — The parser reads the container
1. `ScData::Parser::CommoditiesParser` collects `Components.SCItemResourceContainer`
   (alongside the `SCItemPurchasableParams` and resource-database reads it already does),
   recording `generateRandomQuality` per `sc_key`.
2. A record wins `counted: true` where any of its entities declares
   `generateRandomQuality="1"`; everything else is `false`.
3. `parse_commodity` emits `counted:` in the item hash.
4. Parser test covers: a counted gem, a bulk crate, and a commodity that exists only in the
   resource-type database (no container → bulk).

### Phase 2 — The column, build-fact layered
1. Migration adds `counted` (boolean, null-able) to `commodities` and `commodity_builds`.
2. `CommodityBuild::FACTS` and `READ_THROUGH` gain `:counted`. `FILTERABLE` only if a filter
   is added — it is not, in this phase.
3. `ScData::Loader::CommoditiesLoader#update_params` writes `counted`.
4. Data migration backfills existing `commodity_builds` rows from the newly-loaded
   `commodities.counted`, carrying its own column list per the frozen-list rule.
5. Loader test asserts the fact lands on both the row and the build.

### Phase 3 — Inventories accept pieces
1. `InventoryLedgerEntry::UNITS_BY_CATEGORY` gains a per-record path: the constant stays the
   floor, and a counted commodity item widens it to `["scu", "units"]`.
2. `unit_fits_category` consults the entry's `item` where there is one.
3. `InventoryStockItemChange` and `FleetContractItem` read the same widened rule rather than
   the raw constant.
4. Frontend: `INVENTORY_UNITS_BY_CATEGORY` / `unitsForCategory` take the selected item into
   account, so the unit picker offers `units` where — and only where — the API will accept it.
5. The API has to say which commodities are counted for the picker to know: `counted` on the
   commodity schemas and the `_base.jbuilder`, plus the inventory item-search response.

### Phase 4 — The slot's capacity check (follow-up, not this PR — D5)
1. `useMaterialStock.forCommodity` compares a `units` holding against an `item` cost, the way
   it already compares `scu` against `resource`.
2. The comment explaining the skipped comparison goes, replaced by the pairing rule.
3. `Blueprints/Slot` shows the sufficiency claim for counted materials.

### Phase 5 — Re-parse and load
1. Re-parse the build and push the tree.
2. Load commodities by hand, confirm the eleven carry `counted`.

## Intent Verification

- [ ] **The eleven are marked** — after a re-parse and load, exactly Hadanite, Dolivine,
      Aphorite, Sadaryx, Beradom, Glacosite, Feynmaline, Janalite, Carinite, Saldynium (Ore)
      and Yormandi Eye carry `counted = true`; the other 26 crafting commodities do not.
- [ ] **An inventory records pieces** — a commodity position for a counted commodity can be
      created with `unit: "units"` and is rejected for a bulk one.
- [ ] **Existing rows stay valid** — every SCU commodity position still saves, counted
      commodities included.
- [ ] **The picker matches the API** — the unit dropdown offers `units` exactly where the API
      accepts it, so no pairing 400s from the UI.
- [ ] **The slot answers** — a blueprint slot asking for 170 pieces of Glacosite states
      sufficiency against a `units` holding instead of skipping the comparison.
- [ ] Ruby tests, frontend tests, `bin/rubocop`, `lint:ts` and `api-schema-check` clean.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/commodities_parser.rb` | reads the crates; gains the `ResourceContainer` read |
| `app/lib/sc_data/loader/commodities_loader.rb` | writes row + build; gains `counted` |
| `app/models/commodity.rb` / `app/models/commodity_build.rb` | the fact layering |
| `app/models/concerns/inventory_ledger_entry.rb` | `UNITS_BY_CATEGORY`, `unit_fits_category` |
| `app/models/inventory_stock_item_change.rb`, `app/models/fleet_contract_item.rb` | the two other readers of the constant |
| `app/frontend/frontend/composables/useInventoryOptions.ts` | the mirrored pairing, unit picker |
| `app/views/api/v1/commodities/_base.jbuilder` + `app/api_components/**/commodity*.rb` | the API surface for `counted` |
| `app/frontend/frontend/composables/useMaterialStock.ts` (#5031) | the skipped capacity check |
| `app/models/blueprint_cost_option.rb` | `cost_type`, the other half of the pairing |

## Not in scope (deferred)

- **Converting held stock between the units.** There is no SCU-per-piece figure in the game
  files for these, and inventory positions are keyed by `name`/`category`/`unit`, so the same
  commodity held both ways is simply two positions. Aggregating them would need a rate we do
  not have.
- **A `counted` filter on the commodity catalogue.** No page asks for it yet;
  `CommodityBuild::FILTERABLE` stays as it is, per the fact-filter cost.
- **The other 6 unmatched bulk commodities' provenance.** They are bulk by arithmetic and by
  default; naming their crates is not needed for the answer.

## Discovery Log

- **2026-09-19** Initial research and plan creation. Found #5031 still open, which put
  phase 4 behind a base-branch decision; settled as D5 — off `main`, slot check follows.
- **2026-09-19** D1 verified against the whole build rather than the issue's sample. Reading
  `ResourceContainer` off *whichever* entity carries it — not only the one that matches by
  purchasable key — agrees with the recipes on **all 37 materials** the 4,289 cost options
  ask for (11 counted, 26 bulk, none both ways), against the issue's 31. The 6 the
  purchasable-key match missed are answered rather than assumed bulk.
- **2026-09-19** The rule reaches further than crafting: **56 of the 232** commodities are
  counted, the other 45 being harvestables no recipe asks for — herbs, eggs, horns, the
  vice drugs. All are hand-carried a piece at a time, so an inventory should record them in
  pieces too. That is a widening of the feature, not a false positive.

## Progress
- [ ] Phase 1 — The parser reads the container
- [ ] Phase 2 — The column, build-fact layered
- [ ] Phase 3 — Inventories accept pieces
- [ ] Phase 4 — The slot's capacity check (follow-up, not this PR — D5)
- [ ] Phase 5 — Re-parse and load
