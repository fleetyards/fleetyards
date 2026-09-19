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

### D2 — Two build facts on `commodities`, layered like the other three

`CommodityBuild::FACTS` becomes `%i[name commodity_type description counted]`, with the
column added to both `commodities` and `commodity_builds` and the fact read through the
build. The layering is already in place from #4988's backfill; this widens it by one column.

`counted` is `false` by default rather than null. Bulk is what the app has said about every
commodity it has ever held, so a build parsed before the parser read the container said
exactly that rather than saying nothing — and it keeps the API's boolean a boolean, where a
nullable one reaches the frontend as `boolean | null` and every caller has to answer for a
third case meaning "bulk" anyway.

`piece_volume` (D6) rides alongside it as the fifth fact, nullable, set only where `counted`
is true.

### D6 — `piece_volume`, because the units *are* convertible

The container that declares `generateRandomQuality` also declares its `capacity`, and for a
counted commodity that capacity is **one piece**: Hadanite is `SMicroCargoUnit microSCU="1000"`,
which is 0.001 SCU. Measured over `4.10.1-live.12660092`: **all 56 counted commodities declare
one, none declares two different ones, and no bulk commodity declares one at all** — their
"piece" is a crate, sold in seven sizes from 1 to 32 SCU, so there is no single figure to state.

This is not an optional extra. `InventoryStockItem#volume_scu` answers `net_quantity` directly
for an `scu` position and otherwise asks `item_volume`, which only knew Equipment and
Component. So the moment a commodity position can be recorded in `units`, it lands in
`stock_volume`'s `unmeasured` bucket and the hold-fill figure silently understates itself —
a regression this change would introduce. Reading the piece volume is what closes it.

Read off the counted container and no other: every commodity is also sold in crates that
declare their own capacity, so any other container answers with a crate size.

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

### Phase 2 — The columns, build-fact layered
1. Migrations add `counted` (boolean, `false` by default) and `piece_volume`
   (`decimal(16, 8)`, nullable) to `commodities` and `commodity_builds`.
2. `CommodityBuild::FACTS` and `READ_THROUGH` gain both. `FILTERABLE` gains neither — no
   filter reaches them, and widening the fallback subquery would cost every `currentVersion=false`
   query for nothing.
3. `Commodity#counted?` is redirected by hand: Rails defines the `?` spelling off the column,
   and the column is only the fallback. The first boolean fact in any of the four catalogues,
   which is why none of the others needed it.
4. `ScData::Loader::CommoditiesLoader#update_params` writes both.
5. **No data migration.** One would run at deploy, before any load, with nothing to copy from —
   both columns are new on both tables. The next load writes them; until then `counted` reads
   false, which is what the app already believed.

### Phase 3 — Inventories accept pieces
1. `InventoryLedgerEntry::UNITS_BY_CATEGORY` gains a per-record path: the constant stays the
   floor, and a counted commodity item widens it to `["scu", "units"]`.
2. `unit_fits_category` consults the entry's `item` where there is one.
3. `FleetContractItem` reads the same widened rule rather than the raw constant. The
   implementation moves onto the `InventoryLedgerEntry` module itself, with a `delegate` left
   in `class_methods` — a contract line is not a ledger entry but asks the same question.
4. `InventoryLedgerEntry#item_volume` answers for a counted commodity, so a position recorded
   in pieces still reports its volume (D6).
5. Frontend: `unitsForCategory` / `unitOptionsFor` take the picked item into account, so the
   unit picker offers `units` where — and only where — the API will accept it. Four modals
   pass it through: both inventory item modals, the contract item modal, and the stock-item
   rename.
6. The API has to say which commodities are counted for the picker to know: `counted` and
   `pieceVolume` on the commodity schemas and both `_base.jbuilder`s, plus `counted` on the
   three item references a modal reads when editing something that already exists —
   `InventoryItemRef`, `InventoryStockPosition#item` and `Contracts::FleetContractItemRef`.

### Phase 4 — The slot's capacity check (follow-up, not this PR — D5)
1. `useMaterialStock.forCommodity` compares a `units` holding against an `item` cost, the way
   it already compares `scu` against `resource`.
2. The comment explaining the skipped comparison goes, replaced by the pairing rule.
3. `Blueprints/Slot` shows the sufficiency claim for counted materials.

### Phase 5 — Re-parse, push, load
1. Re-parse the build and push the tree — the loader tests read the tree, not the parser.
2. Bump the CI parsed-tree cache key (`v5` → `v6`, and `v6` → `v7` for the follow-up in
   #5037); it is keyed on the build, and the build
   has not moved.
3. Load commodities by hand after deploy, confirm the eleven carry `counted`. `ScData::CheckJob`
   will not do it: the version is unchanged, so it reads as already loaded.

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
- [ ] **The hold-fill figure survives** — a position recorded in pieces reports a volume
      rather than landing in `stock_volume`'s unmeasured count.
- [ ] **The slot answers** (follow-up) — a blueprint slot asking for 170 pieces of Glacosite
      states sufficiency against a `units` holding instead of skipping the comparison.
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
| `app/models/inventory_stock_item.rb` / `app/models/concerns/inventory_stock.rb` | `volume_scu` and the unmeasured count D6 protects |
| `app/frontend/frontend/composables/useMaterialStock.ts` (#5031) | the skipped capacity check |
| `app/models/blueprint_cost_option.rb` | `cost_type`, the other half of the pairing |

## Not in scope (deferred)

- **Aggregating a commodity held in both units into one position.** `piece_volume` (D6) gives
  the rate, so this is now possible rather than impossible — the original plan said there was
  no SCU-per-piece figure in the game files, and that was wrong. But positions are keyed by
  `name`/`category`/`unit`, so merging them is a change to what a position *is*, not a
  conversion. Left alone deliberately.
- **Admin editing of `counted` and `piece_volume`.** Both are readable in the admin payload
  because `Admin::V1::Schemas::Commodity` inherits the public one, but neither is in
  `CommodityInput`. A wrong value here is a parser bug, and the fix belongs in the parser.
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

- **2026-09-19** Surveying the raw commodity records turned up the piece volume, which
  overturned this plan's own "no SCU-per-piece figure" claim and made D6 a requirement rather
  than an extra. Measured: 56/56 counted commodities declare exactly one, 0/176 bulk ones do.
- **2026-09-19** Re-parsed `live` twice. The first re-parse rewrote **7,795 item files** as
  well as the commodities — the on-disk tree was parsed 2026-09-17T16:02Z, which predates
  #5001, #5007 and #5005, all three of them parser fixes. The second re-parse touched only the
  232 commodity files, confirming the item churn was pre-existing staleness and not this
  change. Whether S3 carries the stale tree too is unverified — it needs the 1Password unlock.

## Progress
- [ ] Phase 1 — The parser reads the container
- [ ] Phase 2 — The columns, build-fact layered
- [ ] Phase 3 — Inventories accept pieces
- [ ] Phase 4 — The slot's capacity check (follow-up, not this PR — D5)
- [ ] Phase 5 — Re-parse, push, load
