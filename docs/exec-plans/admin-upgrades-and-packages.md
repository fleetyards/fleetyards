# Plan: Add Admin CRUD for Model Upgrades and Module Packages

## Context
The admin model edit page has tabs for modules and paints with inline-editable lists, but is missing equivalent tabs for **upgrades** and **packages** (module packages). The backend admin REST API endpoints also don't exist yet — only the traditional Rails web UI controllers exist. We need the full stack: backend API + frontend pages.

## Overview of Changes

### Backend (per resource — model_upgrades and model_module_packages)
1. Admin API controller
2. Routes
3. Authorization policy
4. Jbuilder views
5. OpenAPI input + query schemas
6. Request specs

### Frontend
7. Route entries in `edit/routes.ts`
8. `upgrades.vue` and `packages.vue` edit pages
9. I18n translation keys

### Generation
10. Generate OpenAPI schema (`./bin/generate-schema`)
11. Regenerate Orval hooks (`pnpm generate:api`)

---

## Step 1: Admin API Controllers

### `app/controllers/admin/api/v1/model_upgrades_controller.rb`
- Pattern: follows `model_paints_controller.rb`
- CRUD: index, show, create, update, destroy
- **Plus link/unlink** member actions (like model_modules) — upgrades have a many-to-many relationship with models via `upgrade_kits`
- `index` filters via ransack, query param: `upgradeKitsModelIdEq`
- Permitted params: `name, description, pledge_price, active, hidden, store_image`
- Link/unlink creates/destroys `UpgradeKit` records

### `app/controllers/admin/api/v1/model_module_packages_controller.rb`
- Pattern: follows `model_paints_controller.rb`
- CRUD: index, show, create, update, destroy
- `belongs_to :model` — simpler than upgrades, filter via `modelIdEq`
- Permitted params: `name, description, model_id, pledge_price, active, hidden, production_status, store_image, angled_view, side_view, top_view`

## Step 2: Routes

**File**: `config/routes/admin/api/v1_routes.rb`

```ruby
resources :model_upgrades, path: "model-upgrades", only: %i[index show create update destroy] do
  member do
    put :link
    put :unlink
  end
end

resources :model_module_packages, path: "model-module-packages", only: %i[index show create update destroy]
```

## Step 3: Authorization Policies

### `app/policies/admin/model_upgrade_policy.rb`
```ruby
module Admin
  class ModelUpgradePolicy < BasePolicy
    private def resource_access
      [:model_upgrades]
    end
  end
end
```

### `app/policies/admin/model_module_package_policy.rb`
```ruby
module Admin
  class ModelModulePackagePolicy < BasePolicy
    private def resource_access
      [:model_module_packages]
    end
  end
end
```

## Step 4: Jbuilder Views

### Model Upgrades (`app/views/admin/api/v1/model_upgrades/`)
- `_base.jbuilder` — id, name, description, active, hidden, pledge_price, media (store_image), models array, timestamps
- `_model_upgrade.jbuilder` — cache wrapper
- `index.jbuilder` — items array + meta
- `show.jbuilder` — single upgrade
- `create.jbuilder` — renders show partial

### Model Module Packages (`app/views/admin/api/v1/model_module_packages/`)
- `_base.jbuilder` — id, name, description, active, hidden, pledge_price, production_status, media (store_image, angled_view, side_view, top_view), model, modules array, timestamps
- `_model_module_package.jbuilder` — cache wrapper
- `index.jbuilder` — items array + meta
- `show.jbuilder` — single package
- `create.jbuilder` — renders show partial

## Step 5: OpenAPI Schemas

### Input Schemas
- `app/api_components/admin/v1/schemas/inputs/model_upgrade_input.rb` — name, description, pledgePrice, active, hidden, storeImage, modelId (for link context)
- `app/api_components/admin/v1/schemas/inputs/model_module_package_input.rb` — name, description, modelId, pledgePrice, active, hidden, productionStatus, storeImage, angledView, sideView, topView

### Query Schemas
- `app/api_components/admin/v1/schemas/queries/model_upgrade_query.rb` — idEq, nameCont, nameEq, upgradeKitsModelIdEq
- `app/api_components/admin/v1/schemas/queries/model_module_package_query.rb` — idEq, nameCont, nameEq, modelIdEq

### List Schemas (if not already complete)
- `app/api_components/admin/v1/schemas/model_upgrades/model_upgrades.rb` — items + meta wrapper
- Verify existing module_packages schemas are adequate

## Step 6: Request Specs

### `spec/requests/admin/api/v1/model_upgrades/`
- `index_spec.rb`, `show_spec.rb`, `create_spec.rb`, `update_spec.rb`, `destroy_spec.rb`, `link_spec.rb`
- Pattern: same as model_modules specs with auth checks (401, 403, 404)
- Factory: `:model_upgrade` already exists

### `spec/requests/admin/api/v1/model_module_packages/`
- `index_spec.rb`, `show_spec.rb`, `create_spec.rb`, `update_spec.rb`, `destroy_spec.rb`
- Factory: `:model_module_package` already exists

## Step 7: Frontend Routes

**File**: `app/frontend/admin/pages/models/[id]/edit/routes.ts`

Add two new route entries after modules/paints:
- `admin-model-edit-upgrades` → `upgrades/` path
- `admin-model-edit-packages` → `packages/` path

## Step 8: Frontend Pages

### `app/frontend/admin/pages/models/[id]/edit/upgrades.vue`
- Pattern: follows `modules.vue` (since upgrades also have many-to-many with link/unlink)
- List upgrades filtered by `upgradeKitsModelIdEq: model.id`
- Display: store_image thumbnail + name + pledge price
- Edit form: storeImage (file), name, description, pledgePrice
- Toggle actions: active, hidden
- Link existing upgrade via modal
- Unlink action

### `app/frontend/admin/pages/models/[id]/edit/packages.vue`
- Pattern: follows `paints.vue` (simpler, direct belongs_to)
- List packages filtered by `modelIdEq: model.id`
- Display: store_image thumbnail + name + pledge price + module count
- Edit form: storeImage (file), angledView, sideView, topView, name, description, pledgePrice, productionStatus
- Toggle actions: active, hidden

## Step 9: I18n Keys

**File**: `app/frontend/translations/en/headlines.json`
- `admin.models.edit.upgrades`: "Upgrades"
- `admin.models.edit.packages`: "Packages"
- `admin.models.edit.linkUpgrade`: "Link Existing Upgrade"

**File**: `app/frontend/translations/en/messages.json`
- `confirm.modelUpgrade.destroy`: "Are you sure you want to delete this upgrade? This action can't be reverted."
- `confirm.modelUpgrade.unlink`: "Are you sure you want to unlink this upgrade from the model? The upgrade will still exist but won't be associated with this model."
- `confirm.modelModulePackage.destroy`: "Are you sure you want to delete this module package? This action can't be reverted."

**File**: `app/frontend/translations/en/nav.json`
- `admin.models.edit.upgrades`: "Upgrades"
- `admin.models.edit.packages`: "Packages"

**File**: `app/frontend/translations/en/labels.json`
- `modelUpgrade.hidden`, `modelUpgrade.active`
- `modelModulePackage.hidden`, `modelModulePackage.active`

## Step 10–11: Generate Schema & Orval Hooks

```bash
./bin/generate-schema        # Regenerate OpenAPI schema from specs
pnpm generate:api            # Regenerate Orval hooks (creates useListModelUpgrades, etc.)
```

After generation, the frontend pages will import the auto-generated hooks.

---

## Verification

1. Run backend specs: `rspec spec/requests/admin/api/v1/model_upgrades/ spec/requests/admin/api/v1/model_module_packages/`
2. Run linting: `bundle exec standardrb --fix`
3. Generate schema: `./bin/generate-schema`
4. Generate Orval: `pnpm generate:api`
5. Frontend lint: `pnpm lint`
6. Manual: navigate to a model's edit page and verify Upgrades and Packages tabs appear with working CRUD

## Files to Create/Modify

### New Files (~25)
- `app/controllers/admin/api/v1/model_upgrades_controller.rb`
- `app/controllers/admin/api/v1/model_module_packages_controller.rb`
- `app/policies/admin/model_upgrade_policy.rb`
- `app/policies/admin/model_module_package_policy.rb`
- `app/views/admin/api/v1/model_upgrades/` (4 files)
- `app/views/admin/api/v1/model_module_packages/` (4 files)
- `app/api_components/admin/v1/schemas/inputs/model_upgrade_input.rb`
- `app/api_components/admin/v1/schemas/inputs/model_module_package_input.rb`
- `app/api_components/admin/v1/schemas/queries/model_upgrade_query.rb`
- `app/api_components/admin/v1/schemas/queries/model_module_package_query.rb`
- `app/api_components/admin/v1/schemas/model_upgrades/model_upgrades.rb`
- `spec/requests/admin/api/v1/model_upgrades/` (6 spec files)
- `spec/requests/admin/api/v1/model_module_packages/` (5 spec files)
- `app/frontend/admin/pages/models/[id]/edit/upgrades.vue`
- `app/frontend/admin/pages/models/[id]/edit/packages.vue`

### Modified Files
- `config/routes/admin/api/v1_routes.rb`
- `app/frontend/admin/pages/models/[id]/edit/routes.ts`
- `app/frontend/translations/en/headlines.json`
- `app/frontend/translations/en/messages.json`
- `app/frontend/translations/en/nav.json`
- `app/frontend/translations/en/labels.json`
