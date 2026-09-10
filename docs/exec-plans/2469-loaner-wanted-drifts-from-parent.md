# Wrongfully attributed loaners in fleet view

## Goal

`Vehicle#create_loaner` stops stranding rows when a ship moves between hangar and wishlist, and stops hiding the loaner it just found, so a user's loaners reflect the ships they actually hold — with the rows already damaged repaired.

## Context

Reported three years ago against a real fleet. Two symptoms, which turn out to be two distinct bugs sitting in the same five-line method:

> all the loaners on the list were considered to be commanded by myself […] they were loaners from unpurchased ships
>
> when I removed my ships from the fleet we had no loaners that showed up at all

Both were dismissed at the time as "the underlying loaner system makes this very complicated". They are not complicated; the method one screen further down the same file already does both things correctly.

I first triaged this as fixed by reading the code — `create_loaner` does copy `wanted` from its parent — and had to retract that publicly. It copies `wanted` **at creation only**. Only the data shows the drift.

Resolves #2469

### The evidence

`create_bundled_snub_craft` is the same relationship — a child vehicle derived from a parent — implemented without the defect. Measured on a production snapshot, 2026-09-10:

| | rows | child disagrees with parent | share |
|---|---:|---:|---:|
| `bundled` (no `wanted:` in the lookup) | 6,218 | 1 | 0.02% |
| `loaner` (`wanted:` in the lookup) | 584,809 | 54,429 | **9.31%** |

Of those 54,429, the 36,418 with a wishlisted parent and `wanted: false` on themselves are the ones that reach fleets, because `FleetMembership#update_fleet_vehicle_for_all` consults the loaner row's own flag.

Separately, grouping every user's loaners by model and wishlist state:

| | groups |
|---|---:|
| one loaner, visible | 148,253 |
| **one loaner, hidden** | **115,983** |
| several loaners, all hidden | 24,981 |

A lone loaner has nothing to be deduplicated against, so 140,964 groups where the user should see a loaner and sees none.

## Decisions

### D1 — Drop `wanted:` from the lookup and sync it, mirroring the sibling

```ruby
existing_loaner = Vehicle.where(loaner: true, vehicle_id: id, model_id: model_loaner.id, wanted:, user_id:).first
```

`vehicle_id` already ties the row to this one parent, so `wanted:` narrows nothing legitimate — it only makes the lookup miss rows written under the previous value. The method then creates a second set and leaves the first behind; `remove_loaners` runs `after_destroy`, so nothing reconciles them.

`create_bundled_snub_craft` omits `wanted:` from its lookup and assigns it when it differs. Adopting that shape is a change *towards* the file's own convention, and the 0.02%-versus-9.31% split is the measurement that the shape is the thing that matters.

### D2 — The `hidden` recomputation has to exclude the row it is about

```ruby
existing_loaner.update(hidden: Vehicle.exists?(loaner: true, model_id:, wanted:, user_id:, hidden: false))
```

On the create path this is right: the row does not exist yet, so the question "is a visible loaner of this model already here?" is well posed. On the update path the row *is* in that set, so a visible loaner answers `true` about itself and hides itself. Any second save of the parent — a rename is enough — makes a user's only loaner disappear.

`remove_loaners` already writes the correct form, `.where.not(id: loaner_vehicle.id)`. So this too is a change towards an existing convention rather than a new idea.

### D3 — Repair as a maintenance task, not a data migration

`bin/deploy-release` runs `data:migrate` inside the Kamal pre-deploy hook, so a migration touching ~585k rows would sit in the deploy's critical path. `BackfillHardpointBuildsTask` records this reasoning and `app/tasks/maintenance/` is where its siblings live.

No `dry_run` attribute: one defaulting to true rolls a console run back silently while still reporting "succeeded".

### D4 — The repair drives the fleet side explicitly

`schedule_fleet_vehicle_update` is `after_commit` and returns early when `hidden?`. Repairing a row that stays hidden would therefore fix the vehicle and leave its stale `FleetVehicle` behind. The task enqueues the update itself rather than relying on the callback.

### D5 — Scope stays at these two bugs

The reporter also raised loaners against hangar groups. That part works now: `update_fleet_vehicle_for_hangar_group` unions the parent's `hangar_group_ids` into the loaner's. Nothing to do.

## What changed

### Phase 1 — `create_loaner`
1. Remove `wanted:` from the existing-loaner lookup.
2. Assign `wanted:` on the found row, alongside `hidden`.
3. Exclude the row itself from the `hidden` recomputation.

### Phase 2 — Tests
4. A `VehicleLoanersTest` mirroring `VehicleBundledSnubCraftsTest`, which already covers auto-creation, idempotence on re-save, the `wanted` cascade and destruction — the loaner side has none of these.
5. Two regression tests naming the bugs: a parent flipping `wanted` leaves exactly one loaner carrying the new value, and re-saving a parent does not hide a sole loaner.

### Phase 3 — Repair task
6. `Maintenance::RepairLoanerFlagsTask` — realign `wanted` with the parent, recompute `hidden` per (user, model, wanted) group, and enqueue the fleet-vehicle update for every row it touches.

## Intent Verification

- [ ] **Flipping does not strand** — moving a ship to the wishlist and back leaves one loaner per parent+model, carrying the parent's current value
- [ ] **A lone loaner stays visible** — saving a parent twice does not hide its only loaner
- [ ] **Deduplication still works** — a second parent loaning the same model still yields exactly one visible loaner
- [ ] **Fleets follow** — a loaner whose parent is wishlisted leaves the fleet
- [ ] **The repair converges** — after the task, zero loaner rows disagree with their parent, and no group of one is hidden
- [ ] **The repair is re-runnable** — a second run changes nothing

## Key files

| File | Role |
|------|------|
| `app/models/vehicle.rb` | `create_loaner`, and `create_bundled_snub_craft` as the correct sibling |
| `app/models/fleet_membership.rb` | `update_fleet_vehicle_for_all` reads the loaner's own `wanted` |
| `test/models/vehicle_test.rb` | `VehicleBundledSnubCraftsTest`, the shape the loaner tests mirror |
| `app/tasks/maintenance/` | Repair task, beside its backfill siblings |

## Not in scope (deferred)

- **Loaners against hangar groups** — already correct, see D5.
- **The 18,011 rows with a hangar parent and a wishlisted loaner** — the mirror image of the leak, harmless in fleets because the filter drops them anyway, but repaired by the same task.
- **Making `hidden` a derived value** rather than a stored column, which is what would prevent this class of bug outright. A much larger change than the report warrants.

## Discovery Log

- **2026-09-10** Phases 1-3 implemented. Verified the regression tests earn their place by reverting the fix: `cascades wanted state`, `flipping wanted back and forth` and `re-saving does not hide its only loaner` fail on the old method (2 loaners where 1 is expected, twice; `hidden` true where false is expected), and the five tests covering behaviour that already worked stay green. `bin/ruby-lint` clean.
- **2026-09-10** Research. Confirmed the drift and its mechanism against the production snapshot, and found the second bug — the `hidden` self-hit — while reading the same method. Confirmed `create_bundled_snub_craft` is the same relationship done correctly, and that its data is clean, which is what makes the fix a convention alignment rather than a guess.

## Progress

- [x] Phase 1 — `create_loaner`
- [x] Phase 2 — Tests
- [x] Phase 3 — Repair task
- [ ] Run the repair in production after the fix ships
