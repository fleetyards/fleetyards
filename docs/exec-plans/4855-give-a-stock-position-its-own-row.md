# Give a stock position its own row

## Goal

A stock position is a row in `inventory_positions` that ledger entries point at, so its identity survives a rename and nothing can split or merge one by relabelling an entry.

## Context

A position has no row. It is derived — `GROUP BY name, category, unit` over the entries (`app/models/concerns/inventory_stock.rb:56`) — so identity *is* a mutable label. Six symptoms, one cause:

| symptom | why |
|---|---|
| renaming one entry moves it out of its position, or merges it into another | changing the label changes which group the row is in |
| renaming a position needs a single `update_all` | there is no one row to update, so every entry has to move together |
| that bulk write filed no version | `update_all` runs no callbacks — #4844 |
| an orphaned group of withdrawals hides | `HAVING SUM(...) > 0` cannot tell "emptied" from "broken" |
| a stock series over time relabels its own past | the group key is each row's *current* name |
| the frontend joins strings with `\|\|\|` | there is no id to pass around |

The frontend is the clearest evidence: `Logistics/InventoryItemModal/index.vue:172` builds `` `${name}|||${category}|||${unit}` `` and `:269` splits it apart again to compare field by field. `composables/useInventoryStockList.ts:20` builds a second synthetic key and says why in its own comment — "the stock endpoints return aggregates rather than records, so they have no id to key rows on" — and then filters the whole list client-side for the same reason.

#4849 fenced the specific hole shut (a rename is recorded; splitting a position by renaming one entry is refused). It did not remove the cause. This does.

Resolves #4855

## Decisions

### D1 — A position is the triple, and the quality breakdown lives inside it

The code currently answers "what is a position" two ways, and this has to pick one. Measured, on one position holding three entries at two quality grades:

```
current_stock    → [["Quantanium", 300, 40.0], ["Quantanium", 900, 70.0]]   # 2 rows
stock_positions  → [["Quantanium", 300, 900, 110.0, 3]]                     # 1 row
```

`current_stock` groups by **four** columns including `quality` (`inventory_stock.rb:38`) and is what every `stock#index` renders. `stock_positions` groups by the triple and is what `show`, `update`, `destroy` and the withdrawal guard use — and its own comment says why: *"Rolled up per stock position rather than per quality, matching how withdrawals are checked against stock."*

So the triple is the position, and `quality` is a per-entry attribute that genuinely varies within one (mined ore grades). `inventory_positions` is keyed on `(inventory, name, category, unit)`; the list keeps its per-quality rows, but each now carries the same `positionId`.

That is not a behaviour change — two such rows already share one slug today, and clicking either already lands on the same position. It only makes the existing truth legible instead of implied.

### D2 — Identity moves to the row; the quantities stay derived

`net_quantity`, `quality_min`/`quality_max`, `entries_count` and `last_entry_at` are sums over the ledger. Storing them would let them drift from the entries they claim to describe, and the ledger is the record of truth. They stay computed; only the group key changes:

```ruby
.group(:name, :category, :unit)   # today
.group(:inventory_position_id)    # after
```

### D3 — Two tables, not one polymorphic one

`inventory_positions` and `fleet_inventory_positions`, mirroring the pair that already exists at every other level: `inventories`/`fleet_inventories`, `inventory_items`/`fleet_inventory_items`, with the shared behaviour in a concern. A single polymorphic table would hold identical columns for both cases, which is the argument for it, but it gives up the database-enforced foreign key and it would be the only part of this subsystem shaped that way.

The shared behaviour is `StockPosition`, and it carries the same `inventory_association` trick `InventoryLedgerEntry` uses so both sides are reachable under one name. Note `has_many :positions` cannot be declared directly — Rails infers a `Position` class from it — so the association is named for its table and the alias does the work.

### D3a — `inventory_positions`, not `positions`

`model_positions` already exists (`db/schema.rb:1171`) for ship crew positions, and `positionIds` in the frontend already means those (`Fleets/Missions/ShipModal/index.vue:214`). The table is `inventory_positions` and the column `inventory_position_id`. A bare `position_id` on `inventory_items` would read fine in isolation and be ambiguous everywhere else.

### D4 — Keep the slug, add the id

`slug` is a `required` property of the public `InventoryStockPosition` schema (`app/api_components/v1/schemas/inventory_stock_position.rb:34`) and the path segment of three published endpoints. There is no precedent in the repo for a deprecated or redirected API path, and `oasdiff --fail-on WARN` would flag a path-param rename. So `id` is added and `slug` keeps resolving; the frontend moves to `id` at its own pace.

The slug becomes a stored column on `inventory_positions`, unique per inventory, generated by the existing `update_slugs` hook — which turns `stock_item(slug)` from load-every-position-and-`detect` (`inventory_stock.rb:63`) into a `find_by`.

**The backfill has to disambiguate.** `slug_for` parameterizes the name (`inventory_stock_item.rb:11`), so `"Med Pens"` and `"med-pens"` are two positions today — the `GROUP BY` is case-sensitive — sharing one slug, and `stock_item` resolves whichever `.detect` reaches first. A name containing `--` collides the same way. There is also **no unique index** on the triple today (`db/schema.rb:859`), so identity is currently unenforced. The backfill must detect these and disambiguate rather than assume uniqueness.

### D5 — Two deploys, forced by the pre-deploy hook

`.kamal/hooks/pre-deploy:22` runs `bin/deploy-release`, which is `db:migrate data:migrate` — **before the new containers boot**, retried up to three times. So while the migration runs, the *old* release is still serving writes and knows nothing about `inventory_position_id`. A `NOT NULL` FK cannot land in the same deploy as the code that populates it: the old code's `INSERT` would violate it. Same shape as the column-drop hazard, in the other direction.

1. **Deploy A** — create the table; add `inventory_position_id` **nullable** with a FK; ship find-or-create on every write path and the dual read; backfill.
2. **Deploy B** — `change_column_null false` on the entry foreign keys, once the backfill has run everywhere.

The unique indexes on the *positions* do not wait: the table is new and the previous release never writes to it, so identity can be enforced from the first migration. Only the column on the existing entry tables has to be nullable first.

CI never runs `db:migrate` or `data:migrate` — every job does `db:create db:schema:load` — so a broken migration passes CI and fails in the hook. `db/schema.rb` must be committed with the migration or the column is missing in CI.

### D6 — Backfill as a data migration, with the reason recorded

Production holds **1** `inventory_item` and **11** `fleet_inventory_items`, so this is milliseconds and belongs in `db/data/` next to `20260827150100_backfill_component_builds.rb`. The threshold is documented in the repo: `backfill_hardpoint_builds_task.rb:8` chose a maintenance task instead *because* `data:migrate` runs inside the pre-deploy hook and 22,561 rows would block every deploy behind it. This is four orders of magnitude smaller. The migration header records that measurement, so a future reader knows the choice was made against a number rather than by habit.

### D7 — find-or-create takes the inventory lock first

`withdrawal_does_not_exceed_stock` already takes `inventory.lock!` (`inventory_ledger_entry.rb:231`) to serialise concurrent withdrawals. Resolving a position adds a second contention point, so it is resolved **after** the inventory lock to keep one lock order and avoid a deadlock between a deposit and a withdrawal racing on the same inventory.

The race on the position row itself uses the pattern already in this file's neighbourhood — `Inventory.create_for` (`inventory.rb:63`): `transaction(requires_new: true)`, `create!`, `rescue ActiveRecord::RecordNotUnique` → `find_by!`. The savepoint is what keeps the loser's outer transaction usable.

Two write paths need more than a call: a **ship** inventory may be unsaved until `provisioned_inventory` runs (`vehicle_inventory_scoped.rb:14`), so the position cannot be resolved before provisioning; and the CSV importer (`inventory_item_csv_importer.rb:67`) is a hot loop that memoizes a `{[name, category, unit] => position}` cache for the run rather than doing N lookups.

`Fleets::PurgedFleetRestorer` needs care of its own: `INVENTORY_ITEM_COLUMNS` (`purged_fleet_restorer.rb:23`) is an allowlist copied from a reified version, and `inventory_position_id` must **not** be copied verbatim — it would point at a destroyed position. It has to be re-resolved from the reified name, category and unit.

### D8 — What #4849's machinery becomes

All of it retires, which is the measure of whether this refactor is the right shape:

| #4849 added | why it goes |
|---|---|
| `Versions::BulkUpdateRecorder` | one row moves, so paper_trail files one version by itself |
| `InventoryStock::POSITION_MOVE_REASON` | nothing needs marking as part of a group any more |
| `position_is_moved_as_a_whole` validation | an entry cannot leave its position by being relabelled |
| `InventoryLedgerEntry::POSITION_COLUMNS` | only the validation and the reverter read it |
| the four `oasdiff` ignore entries | the 400 they cover stops being reachable |

**Sequencing.** This branch is cut from `main`, which does not have #4849 yet, so none of the above exists here. #4849 is `CLEAN` and green; it should merge first, then this branch rebases and Phase 5 has something to delete. Built the other way round, the removal has nothing to remove and the conflict surfaces at rebase time instead. `main` has also moved twice since the branch was cut (`#4851`, `#4854`), so a rebase is due regardless.

### D10 — The entries keep their own name, category and unit for now

Once a position owns the identity, the same three columns on every entry are duplicated state that can drift. They cannot go yet, for the reason in D5: the previous release is still writing them while the migration runs, and the backfill reads them to decide which position each entry belongs to.

Dropping them is a third deploy, after Deploy B, and it is a real piece of work rather than a tidy-up — `set_name_from_item`, the ransack attributes, the CSV importer and `PurgedFleetRestorer`'s column allowlist all name them. Recorded here so it is a planned step and not a surprise.

### D9 — Do not converge the two legacy list schemas

`Hangar::Logistics::HangarInventoryStockItem` and `Fleets::Logistics::FleetInventoryStockItem` carry `quality` and type `category`/`unit` as bare strings, because the jbuilder duck-types between the two rollups (`_stock_position.jbuilder:7`). Folding them into `InventoryStockPosition` would **remove** `quality` and **narrow** two properties to enums — three breaking changes for a tidiness gain. They get `id` like everything else and keep their shape. Adding a property, and adding it to a response's `required`, are both non-breaking.

## What changed

### Phase 1 — The table
1. Migration: `inventory_positions` — uuid pk, polymorphic `inventory` (or two nullable FKs; decide against how `Inventory` and `FleetInventory` differ), `name`, `category`, `unit`, `slug`, timestamps.
2. `InventoryPosition` model with the enums from `InventoryLedgerEntry`, `SlugConcern`/`update_slugs`, `has_paper_trail on: VersionedItem::RECORDED_EVENTS`, and an entry in `VersionedItem::ROOTS` so its history is readable in admin.
3. `inventory_position_id` added **nullable** to both item tables, with a FK and an index.

### Phase 2 — Writes
1. find-or-create as a `before_save` on `InventoryLedgerEntry`, which covers all five paths at once — three controllers, the CSV import, the fleet restore — plus the console and the factories. No memoization: the lookup is one hit on a unique index per entry, against the insert it accompanies.
2. `update_stock_item` becomes an update of the position row.
3. `destroy_stock_item` destroys the position and cascades its entries.

### Phase 3 — Backfill
1. `db/data/` migration: one position per distinct triple per inventory, disambiguating slug collisions, then point every entry at its position.
2. Verify no entry is left unpointed before Phase 7.

### Phase 4 — Reads
1. `stock_positions`, `current_stock`, `stock_item`, `stock_volume`, `entries_for_stock_item` and `reference_entry_for` group by and join on the position.
2. The two `*_all_inventory_stock` controllers' raw SQL (`hangar_all_inventory_stock_controller.rb:20`, `fleet_all_inventory_stock_controller.rb:18`).
3. `net_quantity_for` and `withdrawal_does_not_exceed_stock` take a position instead of a triple.
4. Jbuilder: `id` on every position payload, `positionId` beside `stockSlug` on entries. Note `fleet_inventory_stock/index.jbuilder:3` inlines a copy of the shared partial and has to change twice.

### Phase 5 — Retire the fences
Everything in D8, once this branch sits on a main that has #4849.

### Phase 6 — Frontend
1. `id` on the local `StockItem` types, replacing the `\|\|\|` key at all nine sites across the two near-duplicate modals.
2. `useInventoryStockList.ts`: drop the synthetic id; reconsider whether the client-side filter can move to the server now that a position is addressable.
3. The three ransack triples (`nameEq`/`categoryEq`/`unitEq`) become one `positionIdEq` — declared in the three query schemas *and* added to the controller permit lists, or it 400s.
4. The three identical "the rename moved the address" blocks can go: an id does not move.

### Phase 7 — Deploy B
`change_column_null false` on `inventory_position_id` and `fleet_inventory_position_id`, in its own migration and its own deploy.

### Phase 8 — Tests
~120 Ruby tests across 12 stock-specific files and 4 model files, plus two frontend specs. Includes a gap worth closing while in there: `fleet_inventory_item_test.rb` never mirrored the five position-move tests from `inventory_item_test.rb:212`, though the behaviour lives in the shared concern.

## Intent Verification

- [ ] **A rename moves one row** — renaming a position files one version on the position, not one per entry, and no entry row is written.
- [ ] **A position cannot be split** — no write path can move an entry out of its position by changing a label; the entry's FK is the only way.
- [ ] **Emptied and broken are different states** — a position with entries netting to zero still resolves; a position with no entries at all is distinguishable from it.
- [ ] **Quantities still come from the ledger** — no stored net, and no test passes by reading a cached total.
- [ ] **The slug still resolves** — every existing position URL keeps working, including the collision cases the backfill disambiguated.
- [ ] **The withdrawal guard is unchanged in effect** — a withdrawal exceeding its position's stock is still refused, and concurrent withdrawals still serialise.
- [ ] **The old release survives Deploy A** — `inventory_position_id` is nullable until Deploy B, so an insert from the previous release cannot violate it.
- [ ] **#4849's machinery is gone** — the recorder, the reason, the validation and the ignore entries are deleted, and the suite is green without them.
- [ ] **No breaking schema change** — `oasdiff` 1.18.1 against main reports nothing new, with no added ignore entries.

## Key files

| File | Role |
|------|------|
| `app/models/concerns/inventory_stock.rb` | Every rollup: `current_stock` (`:33`), `stock_positions` (`:47`), `stock_item` (`:63`), `stock_volume` (`:84`), `entries_for_stock_item` (`:97`), `update_stock_item` (`:115`), `destroy_stock_item` (`:134`), `reference_entry_for` (`:141`) |
| `app/models/inventory_stock_item.rb` | The PORO and `slug_for` (`:10`) — becomes a view over the row |
| `app/models/inventory_stock_item_change.rb` | Validates a move; `column_values` (`:26`) writes raw enum ints for `update_all` and stops needing to |
| `app/models/concerns/inventory_ledger_entry.rb` | `POSITION_COLUMNS` (`:40`), `net_quantity_for` (`:110`), `position_shared?` (`:205`), `withdrawal_does_not_exceed_stock` (`:226`), `inventory_foreign_key` (`:102`) |
| `app/controllers/concerns/inventory_scoped/stock_actions.rb` | Hangar + vehicle stock actions; `set_stock_item` (`:47`) |
| `app/controllers/api/v1/fleet_inventory_stock_controller.rb` | A full duplicate of the above — fleets do not use the concern |
| `app/controllers/api/v1/{hangar,fleet}_all_inventory_stock_controller.rb` | Raw SQL grouping by five expressions |
| `app/lib/inventory_item_csv_importer.rb` | Per-row name/category/unit (`:44`) — the memoized find-or-create |
| `app/services/fleets/purged_fleet_restorer.rb` | `INVENTORY_ITEM_COLUMNS` (`:23`) must not copy the FK |
| `app/views/api/v1/shared/_stock_position.jbuilder` | Duck-types both rollups (`:7`) |
| `app/views/api/v1/fleet_inventory_stock/index.jbuilder` | Inlines a copy of that partial |
| `app/api_components/v1/schemas/inventory_stock_position.rb` | `required` at `:34` — `id` added here |
| `app/frontend/frontend/components/{Logistics,Fleets/Logistics}/InventoryItemModal/index.vue` | The nine `\|\|\|` sites |
| `app/frontend/frontend/composables/useInventoryStockList.ts` | The synthetic id (`:20`) and the client-side filter (`:24`) |
| `.kamal/hooks/pre-deploy` | Why this is two deploys (`:22`) |

## Not in scope (deferred)

- **The #4718 stock chart.** A stable key is what phase 11 needs, and this provides it, but the chart itself stays there. Note a position row still does not answer "what was it called in January" — that comes from the version trail on the position, which is what #4844 filed.
- **Converging the two legacy list schemas** — D9.
- **The duplicated fleet stock controller, the inlined jbuilder, and the dead `Fleets/Logistics/InventoryCard`** — real cleanups, all adjacent, none of them this change. AGENTS.md is explicit about scope creep.
- **Moving the stock list filter server-side.** Phase 6 reconsiders it because the reason it was client-side disappears, but it is a behaviour change and can follow.

## Discovery Log

- **2026-09-11** Phases 2 and 3 landed. Three things worth recording. The resolution went on the entry as a `before_save` rather than into the five call sites, which made the fleet restore work for free — it re-resolves from the identity instead of copying a foreign key pointing at a position destroyed with the fleet. The unit-fits-category rule is deliberately *not* repeated on the position: entries predating it are grandfathered, so duplicating it would give the backfill a way to fail on exactly the rows it exists for. And `pluck` casts an enum to its label even through `Arel.sql`, so the backfill reads raw rows — integers are what a migration should see.
- **2026-09-11** Two environment notes. `bin/rails data:migrate` cannot be run in a fresh worktree: `db:prepare` stamps no `data_migrations` rows, so it tries all 21 from scratch and dies on an unrelated 2026-03 feature-flags one. Use `data:migrate:up VERSION=`. And `annotaterb` runs on `db:migrate` here, re-annotating one unrelated file left by #4843 each time.
- **2026-09-10** Phase 1 landed: both tables, the `StockPosition` concern, the nullable foreign keys, and 15 tests. Settled three things the plan had left open — two tables rather than one polymorphic one (D3), the position unique indexes can land in Deploy A rather than waiting for Deploy B (D5), and the duplicated identity columns on the entries need a third deploy of their own (D10). Also found that `annotaterb` runs automatically on `db:migrate` here, contrary to the research, and that it re-annotates one unrelated file left behind by #4843 — reverted each time rather than carried in this diff.
- **2026-09-10** Research and plan creation. Two findings changed the shape: `current_stock` groups by four columns including `quality`, so "what is a position" had two answers in the codebase and D1 has to pick one; and the pre-deploy hook migrates before the new containers boot, which forces the nullable-then-not-null split in D5. Also confirmed the identity is unenforced today — no unique index on the triple — and that the slug is lossy enough to collide, so the backfill cannot assume uniqueness.

## Progress

- [x] Phase 1 — The table
- [x] Phase 2 — Writes (find-or-create; `update_stock_item` moves with Phase 4)
- [x] Phase 3 — Backfill
- [ ] Phase 4 — Reads
- [ ] Phase 5 — Retire the fences
- [ ] Phase 6 — Frontend
- [ ] Phase 7 — Deploy B
- [ ] Phase 8 — Tests
