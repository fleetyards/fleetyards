# Fix: Hangar sync creating duplicates when RSI pledge ID changes

Issue: fleetyards/fleetyards#3632
Branch: `fix/3632-hangar-sync-pledge-id-change`

## Problem

When RSI changes a pledge ID (package restructure, melt/rebuy), the hangar sync:
1. Fails to match the existing vehicle by `model_id + rsi_pledge_id` (pledge ID changed)
2. The model-only fallback at line 89 should catch it but fails in edge cases
3. Creates a new duplicate vehicle
4. Moves the original to wanted (wishlist)

## Root Cause Analysis

The sync processes RSI items one at a time. For each item:
1. Try `model_id + rsi_pledge_id` match
2. Fallback to `model_id` only match
3. If neither matches, create new vehicle

After all items processed, any unmatched vehicles are moved to wanted.

The issue: if the fallback fails for any reason (race between shared pledge IDs, model resolution differences), there's no safety net before creating duplicates and moving originals to wanted.

## Solution

Add a reconciliation pass in `sync_vehicles` between the main loop and the "move to wanted" step:

1. After the main loop, identify:
   - **Unmatched RSI items**: items that resulted in a new vehicle creation where an existing vehicle of the same model already exists in the unmatched set
   - **Unmatched vehicles**: vehicles not claimed by any RSI item (about to be moved to wanted)

2. For each unmatched vehicle, check if a newly created vehicle exists with the same `model_id` (and optionally `model_paint_id`). If so, this is likely a duplicate caused by a pledge ID change — delete the new one and claim the original instead.

This is simpler and more robust than trying to fix every possible edge case in the main loop.

## Implementation Steps

### Step 1: Add test for pledge ID change scenario
File: `spec/loaders/hangar_sync_spec.rb`

- Add a test case where an existing vehicle has an old `rsi_pledge_id` and the RSI data comes in with a new pledge ID for the same model
- Verify: existing vehicle is updated (not moved to wanted), no duplicate created

### Step 2: Add reconciliation logic to `HangarSync#sync_vehicles`
File: `app/lib/hangar_sync.rb`

After the main `@ships.each` loop and before the "move to wanted" loop:
- Collect unmatched vehicle IDs (in scope but not in `vehicle_ids`)
- Collect newly imported vehicle IDs (`imported_vehicles`)
- For each imported vehicle, check if there's an unmatched vehicle with the same `model_id` (and `model_paint_id`)
- If found: update the original vehicle with the new pledge ID and sync timestamp, delete the newly created one, move the ID from `imported_vehicles` to `found_vehicles`

### Step 3: Verify existing tests still pass
Run the full hangar sync spec to ensure no regressions.

## Files to Modify

- `app/lib/hangar_sync.rb` — add reconciliation pass
- `spec/loaders/hangar_sync_spec.rb` — add pledge ID change test

## Risk Assessment

Low risk — the reconciliation pass only acts on vehicles that were just created in the same sync run, matching them against vehicles that are about to be moved to wanted. No existing behavior changes for normal sync flows.
