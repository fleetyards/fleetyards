# Hangar Sync: Auto-add Bundled Snub Crafts

## Problem
Some ships ship with bundled snub crafts (or vehicles). Example: the 890 Jump comes with an 85X. When a user syncs their RSI hangar via the browser extension, only the parent ship (890 Jump) is created in Fleetyards — the bundled 85X is not. Users have to add the bundled craft manually.

We want sync (and manual hangar adds) to automatically materialize bundled snub crafts alongside their parent.

## Current state

- **Sync entry**: `POST /api/v1/hangars/sync_rsi_hangar` → `HangarSync` (`app/lib/hangar_sync.rb`). `sync_vehicles` creates a `Vehicle` per ship in the RSI payload. Extension payload contains only `{id, name, type, customName}` — no bundling info.
- **Bundling association already modeled at the Model level**: `Model has_many :snub_crafts, through: :model_snub_crafts` (`app/models/model.rb:194-200`). Join table `model_snub_crafts` columns: `model_id`, `snub_craft_id` (both reference `models`). **No data populated, no admin UI, no seed.**
- **Parent/child vehicle infra already exists**: `Vehicle.vehicle_id` (`app/models/vehicle.rb:29`). Used today only by loaners.
- **Loaner pattern is the direct analog**: `Vehicle#add_loaners` / `#remove_loaners` / `#create_loaner` (`app/models/vehicle.rb:201-239`) iterate `model.loaners` on vehicle create and spawn child `Vehicle(loaner: true, vehicle_id: parent.id)` records. Same shape we need.

## Design decisions

| Question | Decision | Why |
| --- | --- | --- |
| How to flag bundled vehicle records | New `bundled :boolean` column on `vehicles` | Cleaner than overloading `loaner` (semantically wrong — bundled snubs are owned, not loaners); cleaner than relying on `vehicle_id IS NOT NULL` (currently means loaner). |
| Removal behavior | Cascade with parent | Parent destroyed → bundled destroyed. Parent moved to `wanted` → bundled also `wanted`. Mirrors loaner lifecycle and matches RSI reality (sell the 890, lose the 85X). |
| Trigger | `after_create_commit` on `Vehicle`, same place `add_loaners` fires | Covers both sync-created and manually-added vehicles. |
| Data source for bundling | Admin UI on `ModelSnubCraft` (mirror of `ModelLoaner` admin) | Mapping data isn't published on a single canonical RSI URL like loaners are, and we don't want a hardcoded constant. User maintains via UI. |

## Existing files to mirror (loaner pattern → snub-craft equivalent)

| Loaner file | Snub-craft equivalent |
| --- | --- |
| `app/controllers/admin/api/v1/model_loaners_controller.rb` | `app/controllers/admin/api/v1/model_snub_crafts_controller.rb` |
| `app/policies/admin/model_loaner_policy.rb` | `app/policies/admin/model_snub_craft_policy.rb` |
| `app/api_components/admin/v1/schemas/queries/model_loaner_query.rb` | `app/api_components/admin/v1/schemas/queries/model_snub_craft_query.rb` |
| `app/api_components/admin/v1/schemas/inputs/model_loaner_input.rb` | `app/api_components/admin/v1/schemas/inputs/model_snub_craft_input.rb` |
| `app/api_components/admin/v1/schemas/models/loaners/model_loaner.rb` | `app/api_components/admin/v1/schemas/models/snub_crafts/model_snub_craft.rb` |
| `app/api_components/admin/v1/schemas/models/loaners/model_loaners.rb` | `app/api_components/admin/v1/schemas/models/snub_crafts/model_snub_crafts.rb` |
| `app/views/admin/api/v1/model_loaners/_model_loaner.jbuilder` | `app/views/admin/api/v1/model_snub_crafts/_model_snub_craft.jbuilder` |
| `app/frontend/admin/pages/models/[id]/edit/loaners.vue` | `app/frontend/admin/pages/models/[id]/edit/snub-crafts.vue` |
| Admin routes for `model_loaners` | Admin routes for `model_snub_crafts` |

## Steps

### 1. Migration
- Add `bundled :boolean, default: false, null: false` to `vehicles`.
- Add index on `(vehicle_id, bundled)` to speed up the cleanup queries.
- No backfill needed (no bundled vehicles exist yet).

### 2. Vehicle model (`app/models/vehicle.rb`)
Mirror the loaner trio:

- `add_bundled_snub_crafts` — guard with `return if loaner? || bundled?` (no recursion, no bundling onto loaner records). Iterate `model.snub_crafts`, call `create_bundled_snub_craft` for each.
- `create_bundled_snub_craft(snub_model)` — `find_or_create_by` a `Vehicle(bundled: true, vehicle_id: id, model_id: snub_model.id, user_id:, wanted:, public: false)`. If one already exists for this `(vehicle_id, model_id)` pair, leave it alone (idempotent re-sync).
- `remove_bundled_snub_crafts` — `Vehicle.where(bundled: true, vehicle_id: id).destroy_all`.
- `update_bundled_snub_crafts` — keeps `wanted` in sync when the parent toggles.

Hook into the same callbacks `add_loaners` / `remove_loaners` use. Specifically:
- `after_create_commit :add_bundled_snub_crafts` (and an analogous loaner-style call from any other place loaners are propagated, e.g., when `model_id` changes).
- `before_destroy :remove_bundled_snub_crafts` (or `after_destroy_commit`, whichever matches loaners).
- Whatever loaner uses to propagate `wanted` changes — add a bundled-equivalent there.

### 3. HangarSync (`app/lib/hangar_sync.rb`)
- `vehicle_scope` at line 93 currently filters `loaner: false`. Add `bundled: false` so bundled children are not considered when matching the RSI payload and not moved to `wanted` by the reconciliation pass at line 222.
- No direct calls needed — the `after_create_commit` callback on the parent vehicle handles spawning the bundled child.

### 4. Admin UI for `ModelSnubCraft`
- Backend: create the controller, policy, api_components query/input/model schemas, and jbuilder partial as listed in the mirror table above. Wire admin routes (parallel to existing `model_loaners` admin routes).
- Frontend: add `app/frontend/admin/pages/models/[id]/edit/snub-crafts.vue` mirroring the loaners admin page. Add nav entry on the model edit page next to "Loaners".
- Run `./bin/generate-schema` after schemas are in place (do NOT edit `schema.yaml` directly).
- Run `bundle exec standardrb -A` and frontend linting (`pnpm`).

### 5. Tests
- **`spec/models/vehicle_spec.rb`**: parent vehicle creation with `model.snub_crafts.any?` spawns bundled children; destroy cascades; manually added (non-loaner, non-bundled) vehicles also fire bundling; bundled children do not themselves spawn grand-children; idempotent on re-create.
- **`spec/requests/api/v1/hangars/sync_rsi_hangar_spec.rb`** (or wherever the existing sync spec lives): seed `model_snub_crafts` for 890 Jump → 85X, run sync with an 890 Jump payload item, assert one parent + one bundled child created, child has `bundled: true` and `vehicle_id` pointing at parent.
- **`spec/requests/admin/api/v1/model_snub_crafts_spec.rb`**: CRUD coverage mirroring `model_loaners_spec.rb`.
- **Reconciliation regression**: when an 890 Jump's `rsi_pledge_id` is missing in a subsequent sync, the bundled 85X should follow the parent into `wanted: true`, not be left dangling as owned.

## Out of scope
- Populating the `model_snub_crafts` data itself — that's manual admin work the user does after this ships.
- Bundled non-snub vehicles (e.g., a ship that includes a buggy). The `model_snub_crafts` table is named for snubs but is just a model-to-model link; if we later want to bundle ground vehicles, we can either reuse this table or introduce a sibling. Out of scope here.
- Changes to the browser extension. The bundling is inferred server-side; the extension doesn't need to know.

## Risk notes
- The loaner pattern destroys + recreates children aggressively on parent changes. Watch that the bundled equivalent uses `find_or_create_by` so re-syncs don't churn through delete/insert (which would lose any user customizations like `name`, `purchased`, `flagship` flags on the bundled child). Loaners don't have this concern because they're treated as ephemeral.
- `HangarSync` reconciliation at line 222 matches imported vs. unmatched vehicles by `(model_id, model_paint_id)`. If we accidentally include bundled children in either side, we could merge a real 85X with a bundled-snub 85X and destroy one. The `bundled: false` filter on `vehicle_scope` should prevent this, but the spec must cover it.
