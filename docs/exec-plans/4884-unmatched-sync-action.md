# What a sync does with the ships it does not find

## Context

A hangar sync walks the user's RSI pledge list, matches every item against the
vehicles they already have, and then reaches for everything it did *not* match:

```ruby
vehicle_scope.where.not(id: vehicle_ids).find_each do |vehicle|
  vehicle.update!(rsi_pledge_id: nil, rsi_pledge_synced_at: nil, wanted: true)
end
```

One hard-coded answer to a question with several reasonable ones, and it is the
destructive one when a scrape comes back short — a half-loaded RSI page moves
the untouched half of a hangar onto the wishlist.

Follow-up to #4880, which gave the run its first option (`add_bundled_vehicles`)
and built the modal rows this one slots into. Stacked on that branch: the two
share the modal, the store, `SyncRsiHangarInput` and the `imports` table.

## The choice

Carried on the import row, so the job reads it rather than the request:

| value      | what the run does with an unmatched vehicle                       |
| ---------- | ----------------------------------------------------------------- |
| `wishlist` | today's behaviour, and the default — clears the pledge ref, `wanted: true` |
| `delete`   | `Vehicle.delete_with_dependents`, which takes loaners, bundled crafts, loadouts and versions with it |
| `keep`     | nothing is written at all                                         |
| `group`    | nothing is written to the vehicle; it is filed into a hangar group so it can be sorted out by hand |

`group` needs a group of its own — `hangar_group_id` already means "file the
ships the sync *did* match here", and pointing both at one group would put the
matched and the unmatched into the same bucket.

Remembered between runs in the hangar store, the way `syncAddBundledVehicles`
is. Absent from the request means `wishlist`: a client that predates the option
keeps behaving as it did.

### What each one reports

`output` gets a key per action rather than one shared list, so an existing
consumer of `movedVehiclesToWanted` is untouched and a run says which of the
four it actually took:

- `moved_vehicles_to_wanted` — ids (exists today)
- `deleted_vehicles` — **names**, not ids: there is no row left to resolve one from
- `grouped_vehicles` — ids
- `unchanged_vehicles` — ids

`keep` reporting a list matters more than it looks: without it the option is a
silent no-op, and the user never learns which ships the sync failed to find.

## Slices

### 1. The column and the choice

- Migration: `unmatched_vehicles_action` (string, default `wishlist`, not null)
  and `unmatched_hangar_group_id` (uuid, FK to `hangar_groups`, nullify) on
  `imports`.
- `Import::UNMATCHED_VEHICLES_ACTIONS` as a string-backed enum, so `output` and
  the admin imports table read as words rather than integers.
- `Imports::HangarSync` validates that `group` carries a group.

### 2. The run

- `HangarSync#sync_vehicles` branches on `@import.unmatched_vehicles_action`.
- The `@cancelled` guard stays in front of all four: a run that stopped early
  never saw the rest of the pledge list, so every vehicle it had not reached yet
  still looks unmatched. That was already true of the wishlist move; it is
  data loss under `delete`.
- `delete` reads the names before it deletes, sets `notify: false` the way
  `destroy_bulk` does, and goes through `Vehicle.delete_with_dependents` — a
  plain `destroy_all` leaves `vehicle_loadouts` behind and raises on the FK.
- `group` reuses the insert-if-absent shape of `assign_target_group`;
  `task_forces` carries no unique index, so a re-sync would otherwise stack rows.

### 3. The surface

- `HangarSyncUnmatchedActionEnum` under `v1/schemas/enums/`, sourced from the
  model constant.
- `SyncRsiHangarInput` gains `unmatchedVehiclesAction` + `unmatchedHangarGroupId`.
- `HangarSyncResult` gains the three new keys — `additionalProperties: false`
  and an all-keys `required` list means the component has to move with `output`,
  and the cable broadcast assertions fail if it does not.
- `ImportDetails` + `Imports::HangarSync#result_details` gain `deleted`,
  `grouped`, `unchanged`.
- The controller scopes the group id to the user's own groups, the way
  `target_hangar_group_id` already does.

### 4. The modal

- A `BaseSelect` row under the bundled-snub-craft toggle, with a
  `HangarGroupsSelect` that appears only for `group`.
- Store: `syncUnmatchedVehiclesAction`, `syncUnmatchedHangarGroupId`, both
  persisted.
- Seven locales, by hand — there is no Crowdin and no parity check.

## Tests

- Loader: one test per action, plus a cancelled run under `delete` leaving
  everything alone, plus a re-sync under `group` not stacking task forces.
- Endpoint: the choice is recorded; an absent action still moves to the wishlist;
  a `group` action with someone else's group id does not reach that group.
- Vitest: the modal sends the store's values, the group picker is conditional.

## Not in scope

- A per-ship review screen. The group option is the cheap version of that.
- Undo. `delete` is as final as the hangar's own bulk delete.
