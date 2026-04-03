# Carrierwave Removal — Exec Plan

## Current State

- 11 tables have `carrierwave_migrated_at` columns
- All 11 migration tasks completed in production and removed
- Equipment has `store_image` but no `carrierwave_migrated_at` — needs investigation

## ~~Phase 1: Run Remaining Migrations~~ ✅

- [x] Run all migration tasks in production
- [x] Verify all records have `carrierwave_migrated_at` set across all 11 tables

## Phase 2: Switch Models to Active Storage Only

### Strategy

All models currently use a dual pattern: `mount_uploader :X` (Carrierwave) + `has_one_attached :new_X` (Active Storage) with setter overrides that redirect to Active Storage. The plan:

1. Create a DB migration to rename `active_storage_attachments.name` from `new_X` → `X` for all affected records
2. Remove `mount_uploader` calls and setter overrides from models
3. Rename `has_one_attached :new_X` → `has_one_attached :X`
4. Update all references (views, controllers, libs, specs)

Old DB string columns remain for now (removed in Phase 4).

### Step 1: DB Migration — Rename Active Storage Attachment Names

- [ ] Create migration to update `active_storage_attachments.name` from `new_X` to `X`:
  - Model: 13 renames (new_store_image, new_rsi_store_image, new_fleetchart_image, new_top_view, new_side_view, new_front_view, new_angled_view, new_top_view_colored, new_side_view_colored, new_front_view_colored, new_angled_view_colored, new_brochure, new_holo)
  - ModelPaint: 5 renames (front_view already correct)
  - ModelModule: 1 rename
  - ModelModulePackage: 3 renames (front_view already correct)
  - ModelUpgrade: 1 rename
  - Component: 1 rename
  - Manufacturer: 1 rename (new_logo → logo)
  - User: 1 rename (new_avatar → avatar)
  - Fleet: 2 renames (new_logo → logo, new_background_image → background_image)
  - Imports::HangarImport: 1 rename (new_import → import)
  - Image: 0 renames (already `file`)

### ~~Step 2: Update Models~~ ✅

- [x] **Model** — remove 13 `mount_uploader` calls, rename 13 `has_one_attached`, remove `define_method` setter overrides
- [x] **ModelPaint** — remove 6 `mount_uploader`, rename 5 `has_one_attached` (front_view stays)
- [x] **ModelModule** — remove `mount_uploader :store_image`, rename `new_store_image`
- [x] **ModelModulePackage** — remove 4 `mount_uploader`, rename 3 `has_one_attached` (front_view stays)
- [x] **ModelUpgrade** — remove `mount_uploader :store_image`, rename `new_store_image`
- [x] **Component** — remove `mount_uploader :store_image`, rename `new_store_image`
- [x] **Manufacturer** — remove `mount_uploader :logo`, rename `new_logo`, remove setter override, update `to_filter`
- [x] **Image** — remove `mount_uploader :name` (Active Storage `file` already correct)
- [x] **User** — remove `mount_uploader :avatar`, rename `new_avatar`, remove setter override, handle `remove_avatar` via `avatar.purge`
- [x] **Fleet** — remove `mount_uploader :logo` and `:background_image`, rename both, remove setter overrides
- [x] **Imports::HangarImport** — remove `mount_uploader :import`, rename `new_import`, update `import_file_presence` and `set_import_data`
- [x] **Equipment** — removed `mount_uploader :store_image` (no Active Storage needed, model is unused and candidate for full removal)

### ~~Step 3: Update Views~~ ✅

- [x] Simplify `app/views/api/v1/shared/_file.jbuilder` — remove Carrierwave fallback branch and `old_attr` parameter
- [x] Update all ~24 jbuilder files calling `_file` partial: remove `old_attr:`, rename `attr: :new_X` → `attr: :X`
- [x] Fix direct `.url` calls on Carrierwave uploaders (fleetchart_image, brochure, holo in model views)
- [x] Fix `.store_image.present?` → `.store_image.attached?` in views
- [x] Fix `user.avatar.small.url` (Carrierwave variant syntax) in public vehicle/fleet views and mailer templates

### ~~Step 4: Update Controllers~~ ✅

- [x] `models_controller.rb` — update `store_image` and `fleetchart_image` actions
- [x] `frontend/base_controller.rb` — update `compare_image` method to use Active Storage tempfile download
- [x] `frontend/fleets_controller.rb` — update `fleet.logo.url` / `fleet.logo.present?`
- [x] `frontend/hangar_controller.rb` — update `vehicle.model.store_image.url`
- [x] `admin/base_controller.rb` — update `@model.store_image.url`
- [x] `users_controller.rb` — handle `remove_avatar` via `current_user.avatar.purge`
- [x] `hangars_controller.rb` — update permitted params (remove `new_import`)
- [x] `admin/api/v1/models_controller.rb` — rename `new_rsi_store_image` / `new_store_image` in params

### ~~Step 5: Update Library Files~~ ✅

- [x] `app/lib/rsi/models_loader.rb` — rename `new_rsi_store_image` → `rsi_store_image`, `new_store_image` → `store_image`
- [x] `app/lib/rsi/manufacturers_loader.rb` — rename `new_logo` → `logo`
- [x] `app/lib/paints_importer.rb` — rename `new_store_image` → `store_image`

### ~~Step 6: Update Specs~~ ✅

- [x] `spec/requests/admin/api/v1/models/use_rsi_image_spec.rb` — rename attachment references
- [ ] Factory schema comments (cosmetic, can be done with `annotate` later)

### Resolved Risk Areas

- **`compare_image`** — updated to download Active Storage blob to tempfile for MiniMagick
- **`where.not(fleetchart_image: nil)`** — replaced with `.joins(:fleetchart_image_attachment)`
- **Ransack `_blank` filters** — still query DB columns, work for now, break after Phase 4 column removal
- **PaperTrail tracking** — tracks column names, works for now, needs revisiting after Phase 4
- **Equipment** — removed `mount_uploader`, model is unused and candidate for full removal

## Phase 3: Remove Carrierwave Infrastructure

- [ ] Delete all uploaders (`app/uploaders/*.rb` — 9 files)
- [ ] Delete `CarrierwaveToActiveStorageMigration` concern and remaining 3 migration tasks
- [ ] Delete `lib/carrier_wave/validations/active_model.rb`
- [ ] Delete `config/initializers/carrierwave.rb`
- [ ] Remove gems from Gemfile: `carrierwave`, `fog-aws` (if only used by carrierwave), `ssrf_filter`
- [ ] Keep `mini_magick` and `image_processing` if needed by Active Storage variants

## Phase 4: Database Cleanup

- [ ] Migration to remove `carrierwave_migrated_at` from all 11 tables
- [ ] Migration to remove old string columns (`store_image`, `avatar`, `logo`, `background_image`, `import`, etc.) — only after confirming Active Storage is serving all data
- [ ] Remove width/height columns if Active Storage metadata replaces them, or keep if still referenced

## Phase 5: Cleanup

- [ ] Remove AWS credentials for carrierwave (`carrierwave_cloud_key`, etc.) from Rails credentials
- [ ] Update specs/factories to remove carrierwave annotations and references
- [ ] Verify all image serving works via Active Storage URLs
