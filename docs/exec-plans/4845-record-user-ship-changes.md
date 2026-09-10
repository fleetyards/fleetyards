# Record what a user changes on their own ship

## Goal

A user renaming, re-serialling, wishlisting or repainting their own ship files a version, and no machine write does — so that when the history tab is designed there is history to put in it.

## Context

`Vehicle` has had paper_trail since it was added, gated on `author_id` being present. `author_id` is not a column — it is an `attr_accessor` (`app/models/vehicle.rb:47`) assigned in exactly two places, `admin/api/v1/vehicles_controller.rb:29` and `versions/field_reverter.rb:78`. Both are admin paths. Nothing a user does can set it.

Measured against the production dump, 2026-09-10:

```
Fleet             553744
FleetMembership    46745
Model               8503
RoadmapItem         2523
FleetRole            531
Component            480
FleetInventory        10
FleetInventoryItem     7
ModelModule            5
Inventory              1
InventoryItem          1
Vehicle                0
```

Zero, against a table of **1,573,370 rows** — the largest population ever pointed at `versions`, which carries only two indexes (`db/schema.rb:1660-1675`).

Resolves #4845.

## Decisions

### D1 — Two corrections to the issue's premises, found while reading

**The loaner repair files nothing today.** `Maintenance::RepairLoanerFlagsTask` writes through `update_columns` (`app/tasks/maintenance/repair_loaner_flags_task.rb:60,73`), which bypasses paper_trail entirely. The ~54,000 rows it touched were never a version-flood risk, and it is not one of the paths that needs holding out.

**`:destroy` cannot be recorded on `Vehicle`.** `ErasableVersionsConcern` is included at `vehicle.rb:45`, before `has_paper_trail` at `:53`. Rails runs `after_*` callbacks in reverse definition order, so paper_trail's destroy version is written first and `erase_versions` (`erasable_versions_concern.rb:31`, a `delete_all`) removes it in the same transaction. `test/models/admin_edit_attribution_test.rb:103-114` already pins that outcome. So adopting `VersionedItem::RECORDED_EVENTS` verbatim, as the issue suggests, would add a third event that provably writes nothing.

### D2 — No record predicate can separate a user edit from a machine write

This is the reason the issue is a design decision. `HangarSync#sync_vehicles` (`app/lib/hangar_sync.rb:146-292`) calls `vehicle.update!` at ~8 sites writing `name` and `wanted` — the same columns, on the same non-loaner rows, as a user's rename. A predicate on the record sees no difference.

The two candidate guards each leak:

| Guard | Holds out | Leaks |
|---|---|---|
| `loaner? \|\| bundled?` | `create_loaner`, `create_bundled_snub_craft`, `remove_loaners` | `HangarSync`, `Loaders::LoanerJob`, `Rsi::ModelsLoader`, `HangarImporter` |
| `whodunnit.present?` | `HangarSync`, `LoanerJob`, `Rsi::ModelsLoader` (all Sidekiq) | `HangarImporter` — it runs inline in the request (`api/v1/hangars_controller.rb:84`), so the user *is* the whodunnit |

`loaner? || bundled?` holds out 604,464 of 1,573,370 rows (38.4%) and leaves 968,906 user-owned rows exposed to sync. Neither guard alone is sufficient, and stacking them still leaks `HangarImporter`.

So the machine paths are silenced **at their entry points**, with `PaperTrail.request(enabled: false)`, and the record predicate is kept only for the rows that have no history worth reading.

### D3 — `PaperTrail.request(enabled: false)` at four entry points

```
HangarSync#run_with_import       the three sync_* calls        app/lib/hangar_sync.rb
HangarImporter#run               the item loop                 app/lib/hangar_importer.rb
Loaders::LoanerJob#perform       the add_loaners sweep         app/jobs/loaders/loaner_job.rb
Rsi::ModelsLoader#cleanup_paints    the vehicle writes only    app/lib/rsi/models_loader.rb
Rsi::ModelsLoader#cleanup_blocked   the vehicle writes only    app/lib/rsi/models_loader.rb
```

Wrapping the writing portion rather than each write site means a new `update!` inside `HangarSync` is silent by default — the failure mode is a missing version, not a flood. It also silences the in-request cascades those paths trigger, which a per-site guard would not.

In the models loader the block stops short of `model.destroy`: `Model` is versioned and records `:destroy`, and that version is one somebody should still be able to read.

This is a new mechanism in this codebase: `PaperTrail.request(` appears nowhere today except `whodunnit` assignment (`api/base_controller.rb:145`, `admin/api/base_controller.rb:39`). No local precedent to copy.

### D4 — The record predicate becomes `loaner? || bundled?`, not removed

A loaner and a bundled snub craft are derived rows. Their `wanted` and `hidden` are computed from the parent on every parent save (`vehicle.rb:283`, `:329`), so a version on one records a calculation, not a decision. They are held out permanently, not just during a sync.

`set_flagship` (`vehicle.rb:412-420`) is deliberately left recording: it writes `flagship: false` to one sibling, and that is a real consequence of a user's choice.

### D5 — `on: %i[create update]`

`:destroy` is excluded per D1. `:create` is included — a ship entering the hangar is the start of its history, and without it the first version of every ship is an edit to a state nothing recorded. `HangarImporter` and `HangarSync`, the two bulk creators, are silenced by D3, so this does not import 1.57M creates.

### D6 — `only:` gains the user-writable columns it was missing

The current list versions `hidden` and `loaner`, which only an admin can write, and omits three columns a user can. Compared against `vehicle_params` (`api/v1/vehicles_controller.rb:142-149`), adding:

```
model_id  model_paint_id  alternative_names
```

A retrofit and a repaint are exactly the changes a history should show. `hidden` and `loaner` stay for the admin path.

### D7 — `VehicleLoadout` yes; `VehicleModule` and `VehicleUpgrade` no

This answers the issue's open decision, and the answer is not symmetrical.

`VehicleLoadout` is written only by `api/v1/vehicle_loadouts_controller.rb`, through individual `save` / `update` / `destroy` calls (`:26-51`). One user action produces one version. It records cleanly.

`VehicleModule` and `VehicleUpgrade` are torn down and rebuilt on every update (`api/v1/vehicles_controller.rb:51-52`):

```ruby
@vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
@vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
```

Any PATCH that merely *includes* `modelModuleIds` would file a destroy and a create for every module on the ship, changed or not. That records churn, not change. Making it meaningful requires the controller to diff the set instead of rebuilding it — a separate change, and beyond this issue's `size/S`.

All three declare `belongs_to :vehicle, touch: true`, which is the exact Fleet trap `VersionedItem::RECORDED_EVENTS` documents — so whatever `VehicleLoadout` records, `:touch` must not be in it. It ends up spelling `on:` out rather than taking the constant, for the reason in D10; the model comment says why `:touch` is absent so a later edit does not reintroduce it.

### D8 — `VehicleLoadout` joins `ROOTS`, and the schema is regenerated

`"VehicleLoadout" => [:vehicle]`. `Vehicle` already has a policy, so `POLICIES` needs no entry. `VersionedItem::TYPES` is a public schema surface — `Admin::V1::Schemas::Enums::VersionItemTypeEnum:10` derives its OpenAPI `enum` from it — so this requires `./bin/generate-schema` or `api-schema-check` goes red.

It stays out of `Admin::Api::V1::VersionsController::FEED_ACCESS_BY_ITEM_TYPE`: the feed filters `.where.not(author_id: nil)` (`versions_controller.rb:74`) and user edits carry no `author_id`, so a feed entry would show nothing.

### D9 — `move_all_ingame_to_wishlist` keeps recording

`api/v1/hangars_controller.rb:157-174` loops `vehicle.update(wanted: true)`, so one button press files one version per ship. It is a genuine, intentional user change to every ship it touches, and it is bounded by the size of the user's own hangar. Recorded. Flagged here because it is the one user path that can produce hundreds of versions at once, and it is the first place to look if `versions` grows faster than expected.

### D10 — A loadout's versions are erasable, which costs the delete event

Found while implementing, not in the research. `Vehicle has_many :vehicle_loadouts, dependent: :destroy` (`vehicle.rb:107`) and `User has_many :vehicles, dependent: :destroy` (`user.rb:124`). A loadout version carries `name` — free text the owner typed — and `url`, their build. Without `ErasableVersionsConcern` those rows outlive the deleted account, which is the exact thing the concern exists to prevent on `Vehicle` (`vehicle.rb:43-45`).

So `VehicleLoadout` includes the concern. That makes `:destroy` dead weight for the same reason as D1, so it takes `on: %i[create update]` and removing a loadout is not recorded — the same trade `Vehicle` already makes for deleting a ship. Consistency with that decision beats keeping one more event, and the alternative — erasing a loadout's versions when the *vehicle* dies but not when the loadout does — needs ids captured before destroy and is more machinery than this issue warrants.

### D11 — `activate!` records both sides of the switch

Raised in review, and it was a real gap rather than a deferred one. `update_all` skips paper_trail, so activating B filed a version for B and nothing for the A it replaced — a history that says what was switched on but not what it displaced.

Fixing it turned out cheaper than the original deferral assumed. The old `update_all` wrote `active: false` to *every* non-self sibling, nearly all of them already false. Scoping to `.active` and iterating writes at most one row, because that is the invariant `activate!` itself maintains — confirmed against production: 273 loadouts, 221 vehicles with an active one, **max 1 active per vehicle, 0 violations**, and only 5 vehicles hold more than one loadout at all.

So the change records strictly more history while doing strictly fewer writes.

## What changed

### Phase 1 — Record user edits on `Vehicle`
1. `app/models/vehicle.rb` — replace the `if: author_id.present?` guard with `if: -> (record) { !record.loaner? && !record.bundled? }`, set `on: %i[create update]`, extend `only:` with `model_id model_paint_id alternative_names`. Keep the `meta:` block; the admin path still populates it.
2. Rewrite the comment at `:49-52`. Its current rationale cites the UEX sync rewriting commodities and equipment, which is not a `Vehicle` write path at all.

### Phase 2 — Hold the machine writes out
3. Wrap `HangarSync#run_with_import`, `HangarImporter#run`, `Loaders::LoanerJob#perform` and the two `Rsi::ModelsLoader` cleanup paths in `PaperTrail.request(enabled: false)`.

### Phase 3 — Record loadout changes
4. `app/models/vehicle_loadout.rb` — `include ErasableVersionsConcern` and `has_paper_trail on: %i[create update]` (D10).
5. `app/lib/versioned_item.rb` — add `"VehicleLoadout" => [:vehicle]` to `ROOTS`.
6. `activate!` iterates the active siblings instead of `update_all`, so the loadout that stops being active files a version too (D11).
7. `./bin/generate-schema`.

### Phase 4 — Tests
8. `test/models/admin_edit_attribution_test.rb` — the generated "`Vehicle` files nothing when no author made the change" (`:45-51`) pins exactly the behaviour being removed. Move the `Vehicle` entry out of `CASES` (`:16`) and give it the `Component` shape (`:56-70`) instead: records without an author, carries one when given.
9. New `class VersioningTest < VehicleTest` in `test/models/vehicle_test.rb`, following `test/models/fleet_test.rb:63-88`: `assert_difference … 1` plus a `changeset` assertion for a user rename; `assert_no_difference` for the loaner cascade, the bundled cascade, a `HangarSync`-style write inside the disabled block, and `update_columns`.
10. Tests must scope counts by `item_type`/`item_id` — `test_helper.rb:96` parallelizes across processors, so a whole-table count is unsafe.
11. `bundle exec standardrb --fix` on every changed Ruby file, then `bin/ruby-lint`.

## Intent Verification

- [x] **A user rename files a version** — `PATCH /api/v1/vehicles/:id` with a new `name` produces one `Vehicle` version whose `changeset` names `name`.
- [x] **A repaint and a retrofit file a version** — `model_paint_id` and `model_id` appear in a changeset.
- [x] **A hangar sync files nothing** — `HangarSync` over a user with vehicles produces zero `Vehicle` versions.
- [x] **A loaner-bearing save files nothing on the loaner** — saving a parent whose model has loaners produces no version on any `loaner: true` row.
- [x] **The loaner job files nothing** — `Loaders::LoanerJob` produces zero versions.
- [x] **A loadout change files a version** — creating and renaming a `VehicleLoadout` each produce one; deleting one erases its history (D10).
- [x] **A module PATCH files nothing** — per D7, `VehicleModule` records nothing at all.
- [x] **A destroyed vehicle keeps no versions** — `admin_edit_attribution_test.rb:103-114` still passes.
- [~] **The admin history reads a user edit** — verified by reading the controller rather than by a test: `#index` filters only `.where.not(object_changes: nil)`, so an author-less user edit is returned, while `#recent` filters `.where.not(author_id: nil)` and excludes it. It renders `author: null` — a known read-path limitation, listed under Not in scope, not a recording bug.
- [x] **`api-schema-check` is green** after `./bin/generate-schema`.

## Key files

| File | Role |
|------|------|
| `app/models/vehicle.rb` | The `has_paper_trail` call (`:53-63`), the cascades (`:275`, `:323`, `:412`) |
| `app/models/vehicle_loadout.rb` | Gains recording; `activate!` records both sides of the switch |
| `app/models/vehicle_module.rb`, `vehicle_upgrade.rb` | Deliberately untouched (D7) |
| `app/lib/versioned_item.rb` | `ROOTS`, and the `RECORDED_EVENTS` comment that explains the touch trap |
| `app/lib/hangar_sync.rb` | ~8 `update!` sites writing `name` and `wanted` |
| `app/lib/hangar_importer.rb` | Bulk create, inline in the request — the path `whodunnit` cannot exclude |
| `app/jobs/loaders/loaner_job.rb` | `add_loaners` over every vehicle of every loaner-bearing model |
| `app/lib/rsi/models_loader.rb` | `cleanup_paints` (`:337`), `cleanup_blocked` (`:354`) |
| `app/controllers/api/v1/vehicles_controller.rb` | `vehicle_params` (`:142`) is the definition of "user-writable"; `:51-52` is the D7 rebuild |
| `app/controllers/api/v1/hangars_controller.rb` | `move_all_ingame_to_wishlist` (`:157`), the D9 bulk user path |
| `app/models/concerns/erasable_versions_concern.rb` | Why `:destroy` is dead weight (D1) |
| `test/models/admin_edit_attribution_test.rb` | The test that pins the old behaviour and must change |
| `test/models/fleet_test.rb` | `VersioningTest`, the shape to copy |

## Not in scope (deferred)

- **The user-facing history tab.** Per the issue. Worth seeing the recorded shape first.
- **`VehicleModule` / `VehicleUpgrade` recording** — needs the controller to diff rather than rebuild (D7).
- **Attribution on screen.** The admin views resolve the author from `AdminUser` via `author_id` (`_version.jbuilder:13-22`) and never render `whodunnit`, so every user edit shows `author: null`. The data is attributed; the view cannot read it. That is a read-path change and the issue scopes the read path out.
- **An index for user history by time.** The `created_at` index is partial on `author_id IS NOT NULL` (`schema.rb:1673`); user versions fall outside it. Nothing queries user history by time until the tab exists.

## Discovery Log

- **2026-09-10** Confirmed zero `Vehicle` versions against the production dump; `Fleet` has 553,744. `vehicles` is 1,573,370 rows — 38.0% loaner, 0.4% bundled, 61.6% user-owned.
- **2026-09-10** `author_id` is an `attr_accessor`, not a column — the gate can only ever be satisfied by an admin request.
- **2026-09-10** The issue's loaner-repair example is not a version risk: `update_columns` bypasses paper_trail.
- **2026-09-10** `:destroy` is unrecordable on `Vehicle` — `ErasableVersionsConcern` deletes the row in the same transaction.
- **2026-09-10** Neither candidate guard covers every machine write; `HangarImporter` runs inline in the request, so `whodunnit` cannot exclude it. Led to D3.
- **2026-09-10** `VehicleModule`/`VehicleUpgrade` are destroy-and-rebuild on every PATCH — resolved the issue's open decision as "no" for those two.
- **2026-09-10** Implemented. The two `PaperTrail.request(enabled: false)` wrappers are pinned end to end: a real `HangarSync` over three existing vehicles and a real `HangarImporter` run each file zero versions while still renaming and wishlisting. `Rsi::ModelsLoader` is wrapped around the vehicle writes only, so `model.destroy` keeps filing its `Model` version.
- **2026-09-10** A loadout's versions would have outlived a deleted account — led to D10.
- **2026-09-10** Review raised `activate!`'s `update_all`, which the plan had deferred. Measuring it showed the deferral was wrong: scoping to the active siblings records both sides of the switch *and* writes fewer rows. D11, no longer deferred.

## Progress
- [x] Phase 1 — Record user edits on `Vehicle`
- [x] Phase 2 — Hold the machine writes out
- [x] Phase 3 — Record loadout changes
- [x] Phase 4 — Tests
