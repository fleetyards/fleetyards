# Renaming a stock position leaves no trace

## Goal

Renaming or recategorising an inventory stock position files a paper_trail version for every entry it rewrites, attributed to the user who made the change, without giving up the atomicity the bulk update exists to provide.

## Context

`InventoryStock#update_stock_item` moves every entry of a position in one statement:

```ruby
entries_for_stock_item(stock_item).update_all(changed.column_values)
```

`update_all` bypasses callbacks, so paper_trail never runs. The change with the widest reach — it rewrites `name`, `category`, `unit` and `updated_at` on every matching row — is the only one that leaves no record.

This matters here and almost nowhere else. `fleet_inventory_items` carries `added_by`, `member_id` and `entry_type`, so who deposited or withdrew is in the row itself; `inventory_items` hangs off exactly one holder, so only one person can write to it. Paper_trail earns its place on these two tables for one thing — a *later* correction to an existing entry — and the bulk path is exactly that, and exactly what it skips.

Downstream, #4718 phase 11 plans a stock time series read straight from the ledger. A rename in March retroactively moves January's volume onto the new name; with no version, nothing afterwards can tell that this happened, so the chart silently rewrites its own history.

`InventoryStockItem` having no paper_trail is correct and out of scope — it is a computed rollup over a grouped SELECT, not a table.

Resolves #4844

## Decisions

### D1 — Keep the bulk update; write the versions alongside it

The issue leaves two directions open. Direction (b) — per-row saves inside a transaction — is **blocked by validations**, not merely awkward:

- `withdrawal_does_not_exceed_stock` (`app/models/concerns/inventory_ledger_entry.rb:61`, impl `:185`) is gated only on `withdrawal?`, not on which attributes changed, so a name-only save re-runs it. `net_quantity_for` sums over the *new* name, so renaming a withdrawal before its deposits sees 0 stock and raises mid-rename. Deposits-first ordering papers over the simple case but not several withdrawals replayed out of order, and `inventory.lock!` inside the validation would then be taken once per row.
- `referenced_item_exists` (`:62`, impl `:170`) would newly reject any stored entry pointing at a since-deleted `Commodity`/`Component`/`Equipment` — rows that rename fine today. Same class of problem for `no_vector_image` on `image` (`:56`) and `quantity` numericality (`:57`) on legacy rows.

So the fix takes direction (a): materialise the affected entries before the `update_all`, keep the single statement, and file the versions explicitly — all inside one transaction so a failure to record cannot leave a renamed position unrecorded.

### D2 — Reuse paper_trail's own update event, not `paper_trail.update_columns`

Three mechanisms were tried against the real models before choosing. Measured, not reasoned:

| | `object_changes` | `object` |
|---|---|---|
| `paper_trail.update_columns` | correct | **post**-change |
| `paper_trail.save_with_version` | **empty** | post-change |
| `save_with_version(in_after_callback: true)` | correct | correct |
| `Events::Update.new(record, false, false, nil)` after an in-memory assign | correct | correct |

`update_columns` resolves `object` from `attribute_in_database` *after* clearing dirty state, so its `object` describes the row afterwards — confirmed. `PurgedFleetRestorer` (`app/services/fleets/purged_fleet_restorer.rb:96`) reifies `object`, only on `destroy` events today, so nothing breaks; a version whose `object` lies about the previous state is still not worth introducing. It is also a per-row write, which gives up the single statement.

`save_with_version` outside an `after_` callback files a version with an **empty changeset** — it defaults `in_after_callback: false`, which leaves `@record.changes` already cleared by the save. Passing `in_after_callback: true` produces a correct version but claims a context that is not true, and it is still per-row saves.

So: assign the new values to each loaded record in memory (not saved), and let `PaperTrail::Events::Update` build the row. With `in_after_callback` false the event reads each attribute from the database, where dirty tracking still holds the pre-change value — which is exactly what makes `object` the state before the change. Reusing the event also inherits paper_trail's serialization, so enums land as their names (`"commodity"`, not `0`) and the rows are indistinguishable from ones a normal save filed.

The trade is that `Events::Update` is paper_trail's `@api private`. It is contained in one service and pinned by tests that assert the changeset and the reified record, so a gem upgrade that moves it fails loudly rather than quietly writing wrong versions.

Attribution comes for free: both API base controllers already set `PaperTrail.request.whodunnit` (`app/controllers/api/base_controller.rb:144`, `app/controllers/admin/api/base_controller.rb:38`). The inventory models declare no paper_trail `meta`, so `author_id` stays nil by design — `whodunnit` is the actor column for these tables. The version's `created_at` is set to the row's new `updated_at`, the way paper_trail lines a version up with the save that produced it.

### D3 — A position moves as a whole, enforced on the model

A position has no id of its own — it is a `GROUP BY name, category, unit` over the entries (`inventory_stock.rb:52`), so the label *is* the identity. Changing one of those three columns on a single entry therefore moves that entry into a different group, and the entries left behind can end up in a group with no deposits. Measured, on a 100 SCU deposit and a 30 SCU withdrawal, renaming the deposit alone:

```
stock_positions:  [["Quantanium", -30.0], ["Quantanium Ore", 100.0]]
current_stock:    [["Quantanium Ore", 100.0]]
```

The orphaned withdrawal sits at a negative net, and the same `HAVING SUM(...) > 0` that correctly hides a fully-withdrawn position also hides this broken one — so nothing on screen says it happened. It stays addressable by slug, though, so `DELETE /stock/:slug` can still clear it.

This is not new, and the first version of this guard was built on the belief that it was. The item policies permit `:name, :notes, :category, :unit` on a *persisted* entry (`hangar_inventory_item_policy.rb:16`), and `hangar_inventory_items_update_test.rb:50` exercises exactly that with `body: {name: "Renamed Cargo", notes: "moved to hold 2"}`. So a single-entry rename, and a revert of one, both long predate this change.

**The rule: renaming is always an update over every entry of the position, or it is refused.** An entry that is alone in its position *is* the position, so it may still move itself — `PATCH /stock/:slug` on a one-entry position does the identical thing. Anything else goes through `InventoryStock#update_stock_item`.

Enforced as a validation on `InventoryLedgerEntry` rather than in each controller, because there are four ways in — the three item endpoints, the CSV importer, `Versions::FieldReverter`, and the console. `update_all` skips validations, which is exactly why the whole-position path still works and the per-entry path does not.

That also makes the first attempt's `FieldReverter` guard obsolete, so it is gone: the model refuses the same revert, and more precisely — reverting `name` on a one-entry position is harmless and now correctly allowed. `BulkUpdateRecorder` keeps stamping `reason`, which is still worth having: it is what distinguishes "this row moved with its position" from "somebody edited this row" in the admin history.

The params stay permitted so a client gets an explicit 400 rather than a silently dropped field. That makes a `ValidationError` 400 reachable where the schema had only openapi-ruby's auto-injected `SchemaValidationError`, which the endpoint never actually returned — so the two item-update endpoints now declare the real one, and four `oasdiff` ignore entries record the replacement, in the same form `POST /vehicles/bulk` already uses. Verified against `origin/main` with oasdiff **1.18.1**, the version CI pins — the local 1.31.0 words the finding differently and would have written entries that pass here and fail there.

### D4 — No migration, no schema change

The `versions` table already has every column used. The response body is unchanged, so `bin/generate-schema` should be a no-op — to be verified, not assumed.

## What changed

### Phase 1 — Record the rename

1. New service `app/services/versions/bulk_update_recorder.rb`: takes the records an `update_all` is about to change plus the column values, assigns those values in memory, and inserts one `update` version per record in a single `insert_all`.
2. It skips a record whose only change is `updated_at`. Re-submitting a position's current name is the ordinary way to reach that, and a version whose changeset says only `updated_at` is exactly the noise `Maintenance::DropChangelessVersionsTask` exists to clear out again.
3. It skips entirely when paper_trail is disabled globally, for the request, or for the model.
4. `InventoryStock#update_stock_item` loads the entries first, then re-selects them **by id** for the `update_all`, so the rows that get versioned are exactly the rows that moved rather than whatever the name/category/unit predicate matches on a second pass. Both statements run in one transaction: a rename that cannot be recorded does not happen.
5. `touch` and the returned `InventoryStockItemChange` are unchanged.

### Phase 2 — A position moves as a whole

1. `InventoryLedgerEntry::POSITION_COLUMNS` names the three columns that define a position; `InventoryStock::POSITION_MOVE_REASON` names what a whole-position move stamps on the versions it files, and `BulkUpdateRecorder` takes a `reason:` and writes it.
2. `InventoryLedgerEntry` validates `position_is_moved_as_a_whole` on update: if any position column is changing and another entry of the same inventory still shares the old name, category and unit, the change is refused per offending column. Compared against `attribute_in_database`, since the position an entry is leaving is the one it is still grouped under.
3. The two item-update endpoints that only had the auto-injected 400 now declare the real `ValidationError` one, with four matching `oasdiff` ignore entries.

### Phase 3 — Tests

1. Extend `test/integration/api/v1/hangar_inventory_stock_update_test.rb` — assert a rename files one version per moved entry, each with the expected changeset and the requesting user in `whodunnit`.
2. Same for `test/integration/api/v1/fleets_inventory_stock_update_test.rb` (behind the `fleet_logistics` flag) and `test/integration/api/v1/vehicle_inventory_stock_update_test.rb`.
3. Add a model-level test for `Inventory#update_stock_item` — there is none today, and `grep update_stock_item test/` returns nothing. Cover: version count matches entry count, a rejected change files nothing, and a category+unit move records all three fields.
4. Assert the rejection path is unchanged: an invalid `InventoryStockItemChange` still returns 400 and writes neither rows nor versions.
5. Assert atomicity directly: with the recorder stubbed to raise, the rename rolls back and no version survives.
6. Add a reverter test asserting `name` on an `InventoryItem` version is refused.
7. Follow the assertion style in `test/models/admin_edit_attribution_test.rb:32` (`assert_difference` on the scoped version count, then `version.changeset.keys`).

## Intent Verification

- [x] **A rename is traceable** — after renaming a position, `PaperTrail::Version` holds one `update` row per moved entry, and its changeset names the old and new `name`.
- [x] **A recategorisation is traceable** — moving `category` and `unit` records all changed fields, not just `name`.
- [x] **The actor is recorded** — each version's `whodunnit` is the id of the user who called the endpoint.
- [x] **Atomicity survives** — a failure while recording leaves the entries unrenamed; the position is never half-moved, and never moved without a record.
- [x] **Rejections stay silent** — an invalid change still returns 400 and files no version.
- [x] **A position cannot be split by one entry** — renaming or recategorising an entry that shares its position is refused, whichever way in; an entry alone in its position may still move itself, and the whole-position path is unaffected.
- [x] **Nothing else regressed** — `destroy_stock_item` versions as before, `InventoryStockItem` still has no paper_trail, and `bin/generate-schema` produces no diff.

## Key files

| File | Role |
|------|------|
| `app/models/concerns/inventory_stock.rb` | `update_stock_item` (`:101`), `entries_for_stock_item` (`:92`) — the fix lands here |
| `app/models/inventory_stock_item_change.rb` | Validates the change; `column_values` (`:26`) is what `update_all` writes |
| `app/models/inventory_item.rb` | `has_paper_trail` (`:32`), table `inventory_items` |
| `app/models/fleet_inventory_item.rb` | `has_paper_trail` (`:37`), table `fleet_inventory_items` |
| `app/models/concerns/inventory_ledger_entry.rb` | `withdrawal_does_not_exceed_stock` (`:61`, `:185`) — why direction (b) is blocked |
| `app/lib/versioned_item.rb` | `RECORDED_EVENTS` (`:24`) excludes touch; both item models are in `ROOTS` |
| `config/initializers/paper_trail.rb` | Re-opens `PaperTrail::Version`; json `object`/`object_changes` |
| `app/services/versions/bulk_update_recorder.rb` | New — builds and inserts the versions for a bulk update |
| `app/services/versions/field_reverter.rb` | Field-level revert (`:44`, `:66`) — inherits the model rule |
| `app/controllers/concerns/inventory_scoped/stock_actions.rb` | Shared `update` action (`:20`) for hangar and vehicle |
| `app/controllers/api/v1/fleet_inventory_stock_controller.rb` | Its own `update` (`:29`) — does not use the concern |
| `app/controllers/api/base_controller.rb` | Sets `PaperTrail.request.whodunnit` (`:144`) |
| `app/services/fleets/purged_fleet_restorer.rb` | Reifies `object` (`:96`) — why `object` must stay pre-change |

## Not in scope (deferred)

- **Surfacing renames in the ledger history UI** — `[item].vue` re-queries entries by `nameEq/categoryEq/unitEq`, so after a rename the old rows appear under the new name with nothing marking the change. Belongs with #4718 phase 11, which is where the stock time series is built.
- **Versioning `touch`** — deliberately excluded by `VersionedItem::RECORDED_EVENTS`; `Maintenance::DropChangelessVersionsTask` exists to clean up exactly these.
- **An actor column on `inventory_items`** — unnecessary; the inventory has a single holder, and `whodunnit` covers the correction case.
- **Backfilling versions for past renames** — no record exists to reconstruct them from.
- **Repairing positions already split** — nothing here backfills a negative position an earlier single-entry rename left behind. The stock `DELETE` clears one, but the position stays addressable only by slug and absent from the list, so finding them wants a maintenance task.
- **Deleting an entry, or a run of them, from the inventory** — the natural way to fix a mislabelled entry once per-entry renaming is refused, and the answer to "I mislabelled one of five deposits". For whoever is responsible for that inventory: the officer for a fleet, the owner for a hangar or a ship. A feature of its own, not a clause in this fix.

## Discovery Log

- **2026-09-10** Replaced the reverter guard with a model validation, on the rule that renaming is always an update over every entry of a position or is refused. An entry alone in its position is exempt, because that is the same operation. The reverter guard is gone as redundant and less precise. Confirmed the oasdiff consequence with the CI-pinned 1.18.1.
- **2026-09-10** Corrected the D3 guard after finding the premise wrong: the item policies already permit `name` on a persisted entry, so single-entry renames — and reverts of them — long predate this change. Narrowed the refusal to versions stamped with the position-move reason. Recorded the pre-existing endpoint hole as out of scope.
- **2026-09-10** Built. All three phases landed; `bin/generate-schema` confirmed a no-op, so no swagger or generated-client changes. Tests: `test/models/inventory_test.rb` (23), the three stock update integration files (32), `test/integration/admin/api/v1/versions_test.rb` (18), and the related model/service files (82) all green. One thing the plan got wrong: hand-assembling the version rows was unnecessary and worse — paper_trail's own update event produces them correctly if the records arrive assigned but unsaved, and that inherits its serialization. See the table in D2 for what each mechanism actually writes.
- **2026-09-10** Initial research and plan creation. Confirmed `update_all` is the only untraced write on this path (`destroy_stock_item` uses `destroy_all` and versions correctly), that no precedent exists in the repo for hand-writing versions after a bulk update, and that direction (b) is blocked by two validations rather than one. Found the `FieldReverter` consequence, which the issue does not mention and which the fix has to close.

## Progress

- [x] Phase 1 — Record the rename
- [x] Phase 2 — Guard the revert path
- [x] Phase 3 — Tests
