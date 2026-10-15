# Ore pods and salvage storage as their own figure, like external fuel pods

Working plan for #5721. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A ship's mining ore pods and salvage storage are a model fact of their own, served by the API and shown on the ship page beside external fuel pods, never as cargo.

## What changed

### Phase 1 — Fact and loader
1. Migration: `storage_containers` (serialized YAML string) on `models` and `model_builds`, as `crew` was added.
2. `ModelBuild`: `FACTS`, `serialize`, `STRUCTURED_FACTS`, `LATE_FACTS`; `Model`: `serialize`, paper_trail list.
3. `ModelsLoader#update_storage_containers`: game-file hardpoints whose component is a `Container` (ore pod) or `SalvageInternalStorage` with `capacity > 0`, as `{name, componentName, capacity, kind: ore|salvage}`. Collapsed pods (capacity 0) are skipped.
4. `Hardpoint#set_category`: `hardpoint_mining_pod*` no longer `cargogrid`; data migration for the rows already loaded.

### Phase 2 — API
1. Shared schema `StorageContainer`; `Model` schema `storageContainers`; public and admin jbuilder; admin input and permitted params; regenerate schemas and clients.

### Phase 3 — Ship page
1. `Models/StorageContainers` (ore pods and salvage storage, count and total per kind), mounted in `Models/Hardpoints` beside `ExternalFuelTanks`; admin `cargo-and-fuel` JSON view; labels in all locales.

## Intent Verification

- [ ] **Separate** — the ship page shows ore pods and salvage storage in their own section, never in cargo or the cargo grid
- [ ] **Not cargo grid** — mining pod hardpoints are no longer categorised `cargogrid`
- [ ] **No guesses** — ROC/ROC-DS pods without a capacity in the data show none (locally they carry 1.2/3.4, so they do show)

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/loader/models_loader.rb`, `base_loader.rb` | extraction |
| `app/models/model_build.rb`, `app/models/model.rb` | fact |
| `app/models/hardpoint.rb` | mining pod category |
| `app/views/api/v1/models/_base.jbuilder`, `app/api_components/...` | API |
| `app/frontend/frontend/components/Models/ExternalFuelTanks`, `Models/Hardpoints/index.vue` | pattern and mount |

## Discovery Log

- **2026-10-15** The parsed tree already carries both: `Container`/`Cargo` ore pods with `type_data.capacity`, and `SalvageInternalStorage` (name nil) with capacity. No re-parse needed. Values fill on the next `load:models`.

## Progress
- [ ] Phase 1 — Fact and loader
- [ ] Phase 2 — API
- [ ] Phase 3 — Ship page
