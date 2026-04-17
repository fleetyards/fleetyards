# Remove `sc_identifier` Column from Model and Component

## Context

The `sc_identifier` column maps models to Star Citizen game data files (e.g. `ORIG_600i` -> `data/sc_data/parsed/live/models/orig_600i.json`). Now that slugs include the manufacturer code (`orig-600i`), the identifier can be derived via `slug.tr('-', '_')`.

Data analysis shows the derived value matches game files **better** than many stored sc_identifiers (trailing underscores, stale hyphens). Among 28 mismatches between stored and derived values, the derived version finds the correct file in 6 cases where the stored value fails. Only 3 stored values find files the derived version doesn't (manual overrides mapping variants to base models).

The `in_game?` method should check if the SC data file exists on disk rather than relying on the column.

## Decisions

- **Derive identifier from slug**: `slug.tr('-', '_')` via a `sc_data_identifier` helper method
- **`in_game?` based on file existence**: Check if the SC data JSON file exists on disk (memoized)
- **Keep API field**: Serialize `scIdentifier` from the derived helper for backward compatibility
- **3 edge-case models** (retaliator bomber, dragonfly star kitten, aurora mk-ii): Accept that they won't match files until SC data updates. These are variant/edition mappings that were manually overridden anyway.

---

## Step 1: Add Derived Helper and Update `in_game?`

**File**: `app/models/model.rb`

- Add `sc_data_identifier` method returning `slug&.tr('-', '_')`
- Change `in_game?` to check file existence at `data/sc_data/parsed/{environment}/models/{sc_data_identifier}.json` with memoization (`@in_game` instance variable)
- Remove `sc_identifier` from `ransackable_attributes`

## Step 2: Update SC Data Loaders

**File**: `app/lib/sc_data/loader/models_loader.rb`

- Change filter from `Model.where.not(sc_identifier: nil)` to `Model.find_each` (all models have slugs)
- Change guard from `model.sc_identifier.blank?` to `model.slug.blank?`
- Use `model.sc_data_identifier` instead of `model.sc_identifier` in `load_model_data`

**File**: `app/lib/sc_data/loader/items_loader.rb`

- Remove legacy `Component.find_by(sc_identifier: ...)` fallback lookup

## Step 3: Update RSI Models Loader

**File**: `app/lib/rsi/models_loader.rb`

- Remove `resolve_sc_identifier` method entirely
- Remove sc_identifier-based model lookup fallback
- Remove `updates[:sc_identifier] = ...` assignment

## Step 4: Update Views

**File**: `app/views/api/v1/models/_base.jbuilder`
- Change to `json.sc_identifier model.sc_data_identifier` (backward compatible)
- Change erkul fallback to `model.erkul_identifier.presence || model.sc_data_identifier`

**File**: `app/views/admin/api/v1/models/_base.jbuilder`
- Same changes

**Files**: `app/views/api/v1/vehicles/_export.jbuilder`, `app/views/api/v1/fleet_vehicles/_export.jbuilder`
- Change `ship_code` to use `model.sc_data_identifier`

## Step 5: Update Admin Controllers

**File**: `app/controllers/admin/api/v1/models_controller.rb`
- Remove `:sc_identifier` from permitted params
- Remove `:sc_identifier_blank` from query params
- Change reload conditionals from `sc_identifier.present?` to `slug.present?`

**File**: `app/controllers/admin/api/v1/components_controller.rb`
- Remove `:sc_identifier` from permitted params

## Step 6: Update Seeds and Specs

**File**: `db/seeds/01_manual_models.rb` — Remove `sc_identifier` assignments

**Spec files** — Remove `sc_identifier:` from factory calls, update assertions

## Step 7: Migration

- Remove `sc_identifier` column from `models` table
- Remove `sc_identifier` column from `components` table
- Remove `sc_identifier` from `Component.ransackable_attributes`

## Verification

1. Run `bin/rails runner` comparing `sc_data_identifier` output vs game files on disk
2. Run `bundle exec rspec spec/loaders/`
3. Check API response still includes `scIdentifier` field
4. Verify `in_game?` returns correct values for known flight-ready models
