# Plan: Fill Blank Admin Pages

## Context

Several admin pages are blank stubs (just a heading with no functionality). The goal is to implement them with real content following the same patterns as the fully-implemented models pages (list with FilteredList/BaseTable/Paginator, edit/create forms with vee-validate + TanStack Query mutations).

## Blank Pages Inventory

| # | Page | Current State | API Status |
|---|------|--------------|------------|
| 1 | `admin/pages/components/index.vue` | Heading only | List + Show endpoints exist |
| 2 | `admin/pages/components/create.vue` | Heading only | No create endpoint |
| 3 | `admin/pages/components/[id]/edit.vue` | Heading only | No update endpoint |
| 4 | `admin/pages/manufacturers/create.vue` | Heading only | No create endpoint |
| 5 | `admin/pages/manufacturers/[id]/edit.vue` | Heading only | No update endpoint |
| 6 | `admin/pages/models/create.vue` | Heading only | Create endpoint exists |
| 7 | `admin/pages/models/paints/create.vue` | Heading only | No create endpoint |
| 8 | `admin/pages/models/paints/[id]/edit.vue` | Heading only | No show/update endpoint |
| 9 | `admin/pages/users/[id]/edit.vue` | Heading only | Routes declared, not implemented |
| 10 | `admin/pages/admins.vue` | Heading only | Only `me` action implemented |
| 11 | `admin/pages/fleets.vue` | Heading only | No admin API at all |

**Maintenance pages** (features, pghero, tasks, workers) are intentional redirects to Rails pages — not in scope.

---

## Implementation Order

Work is grouped by resource and ordered by dependency (backend first, then frontend). Each resource follows the pattern:
1. Add backend controller actions + permitted params
2. Add jbuilder views for new actions
3. Write RSpec request specs (swagger_doc format)
4. Regenerate OpenAPI schema → regenerate TypeScript client
5. Build frontend components and fill pages

---

### Step 1: Components List Page (frontend only)

**No backend changes needed** — `index` and `show` endpoints already exist.

Files to create:
- `app/frontend/admin/composables/useComponentFilters.ts` — wraps `useFilters<ComponentQuery>()`
- `app/frontend/admin/components/Components/FilterForm/index.vue` — filter form (name search, item_type dropdown, component_class dropdown)

Files to modify:
- `app/frontend/admin/pages/components/index.vue` — full list page using FilteredList + BaseTable + Paginator

Reference: `admin/pages/models/index.vue`, `admin/components/Models/FilterForm/index.vue`

---

### Step 2: Models Create Page (frontend only)

**No backend changes needed** — `create` endpoint exists, `ModelCreateInput` type exists.

Files to modify:
- `app/frontend/admin/pages/models/create.vue` — create form reusing `admin/components/Models/Form/index.vue` with create mutation

Reference: `admin/pages/models/[id]/edit/index.vue` (uses the same Form component for update)

---

### Step 3: Manufacturers Create & Edit (full stack)

**Backend:**

Files to modify:
- `config/routes/admin/api/v1_routes.rb` — change `only: %i[index show]` to `only: %i[index show create update destroy]`
- `app/controllers/admin/api/v1/manufacturers_controller.rb` — add `create`, `update`, `destroy` actions + `set_manufacturer` for update/destroy + `manufacturer_params` method

Files to create:
- `app/views/admin/api/v1/manufacturers/create.jbuilder`
- `app/views/admin/api/v1/manufacturers/update.jbuilder`
- `spec/requests/admin/api/v1/manufacturers/create_spec.rb`
- `spec/requests/admin/api/v1/manufacturers/update_spec.rb`
- `spec/requests/admin/api/v1/manufacturers/destroy_spec.rb`

Permitted params: `name`, `long_name`, `code`, `description`, `known_for`, `logo`, `sc_ref`

**Frontend:**

Files to create:
- `app/frontend/admin/components/Manufacturers/Form/index.vue` — form fields: name, long_name, code, description, known_for, logo upload, sc_ref
- `app/frontend/admin/composables/useManufacturerUpdateMutation.ts`

Files to modify:
- `app/frontend/admin/pages/manufacturers/create.vue` — create form
- `app/frontend/admin/pages/manufacturers/[id]/edit.vue` — edit form

---

### Step 4: Components Create & Edit (full stack)

**Backend:**

Files to modify:
- `config/routes/admin/api/v1_routes.rb` — change `only: %i[index show]` to `only: %i[index show create update destroy]`
- `app/controllers/admin/api/v1/components_controller.rb` — add `create`, `update`, `destroy` actions + `component_params` method

Files to create:
- `app/views/admin/api/v1/components/create.jbuilder`
- `app/views/admin/api/v1/components/update.jbuilder`
- `spec/requests/admin/api/v1/components/create_spec.rb`
- `spec/requests/admin/api/v1/components/update_spec.rb`
- `spec/requests/admin/api/v1/components/destroy_spec.rb`

Permitted params: `name`, `component_class`, `component_type`, `component_sub_type`, `size`, `grade`, `item_class`, `item_type`, `manufacturer_id`, `description`, `hidden`, `store_image`, `sc_identifier`, `sc_key`, `sc_ref`

**Frontend:**

Files to create:
- `app/frontend/admin/components/Components/Form/index.vue` — form with fields above
- `app/frontend/admin/composables/useComponentUpdateMutation.ts`

Files to modify:
- `app/frontend/admin/pages/components/create.vue` — create form
- `app/frontend/admin/pages/components/[id]/edit.vue` — edit form

---

### Step 5: Model Paints Create & Edit (full stack)

**Backend:**

Files to modify:
- `config/routes/admin/api/v1_routes.rb` — change `only: %i[index]` to `only: %i[index show create update destroy]`
- `app/controllers/admin/api/v1/model_paints_controller.rb` — add `show`, `create`, `update`, `destroy` actions + `model_paint_params` method

Files to create:
- `app/views/admin/api/v1/model_paints/show.jbuilder`
- `app/views/admin/api/v1/model_paints/create.jbuilder`
- `app/views/admin/api/v1/model_paints/update.jbuilder`
- `spec/requests/admin/api/v1/model_paints/show_spec.rb`
- `spec/requests/admin/api/v1/model_paints/create_spec.rb`
- `spec/requests/admin/api/v1/model_paints/update_spec.rb`
- `spec/requests/admin/api/v1/model_paints/destroy_spec.rb`

Permitted params: `name`, `description`, `model_id`, `active`, `hidden`, `on_sale`, `pledge_price`, `production_status`, `production_note`, `store_url`, `store_image`, `rsi_store_image`, `fleetchart_image`, `top_view`, `side_view`, `angled_view`

**Frontend:**

Files to create:
- `app/frontend/admin/components/ModelPaints/Form/index.vue`
- `app/frontend/admin/composables/useModelPaintUpdateMutation.ts`

Files to modify:
- `app/frontend/admin/pages/models/paints/create.vue` — create form
- `app/frontend/admin/pages/models/paints/[id]/edit.vue` — edit form

---

### Step 6: Users Edit (full stack)

**Backend:**

Files to modify:
- `app/controllers/admin/api/v1/users_controller.rb` — add `show`, `update` actions + `user_params` + `set_user`
- `config/routes/admin/api/v1_routes.rb` — change users routes to `only: %i[index show update destroy]` (remove `create`)

Files to create:
- `app/views/admin/api/v1/users/show.jbuilder`
- `app/views/admin/api/v1/users/update.jbuilder`
- `spec/requests/admin/api/v1/users/show_spec.rb`
- `spec/requests/admin/api/v1/users/update_spec.rb`

Permitted params (admin-editable): `username`, `email`, `rsi_handle`, `sale_notify`, `public_hangar`, `public_hangar_loaners`, `public_wishlist`, `hide_owner`, `tester`

**Frontend:**

Files to create:
- `app/frontend/admin/components/Users/Form/index.vue`

Files to modify:
- `app/frontend/admin/pages/users/[id]/edit.vue` — edit form

---

### Step 7: Admin Users Management (full stack)

**Backend:**

Files to modify:
- `app/controllers/admin/api/v1/admin_users_controller.rb` — add `index`, `show`, `create`, `update`, `destroy` actions
- `app/policies/admin/admin_user_policy.rb` — may need to allow super_admins to manage other admins

Files to create:
- `app/views/admin/api/v1/admin_users/index.jbuilder`
- `app/views/admin/api/v1/admin_users/show.jbuilder`
- `app/views/admin/api/v1/admin_users/create.jbuilder`
- `app/views/admin/api/v1/admin_users/update.jbuilder`
- `spec/requests/admin/api/v1/admin_users/index_spec.rb`
- `spec/requests/admin/api/v1/admin_users/create_spec.rb`
- `spec/requests/admin/api/v1/admin_users/update_spec.rb`
- `spec/requests/admin/api/v1/admin_users/destroy_spec.rb`

Permitted params: `username`, `email`, `password`, `password_confirmation`, `super_admin`, `resource_access`

**Frontend:**

Files to create:
- `app/frontend/admin/composables/useAdminUserFilters.ts`
- `app/frontend/admin/components/AdminUsers/FilterForm/index.vue`
- `app/frontend/admin/components/AdminUsers/Form/index.vue`
- `app/frontend/admin/components/AdminUsers/Actions/index.vue`
- `app/frontend/admin/components/AdminUsers/Actions/Items.vue`

Files to modify:
- `app/frontend/admin/pages/admins.vue` — restructure into list page (or create sub-pages like `admins/index.vue`, `admins/[id]/edit.vue`, `admins/create.vue` depending on current routing setup)

---

### Step 8: Fleets Management (full stack)

**Backend:**

Files to create:
- `app/controllers/admin/api/v1/fleets_controller.rb` — full CRUD controller
- `app/policies/admin/fleet_policy.rb` — authorization policy
- `app/views/admin/api/v1/fleets/_base.jbuilder`
- `app/views/admin/api/v1/fleets/_fleet.jbuilder`
- `app/views/admin/api/v1/fleets/index.jbuilder`
- `app/views/admin/api/v1/fleets/show.jbuilder`
- `app/views/admin/api/v1/fleets/create.jbuilder`
- `app/views/admin/api/v1/fleets/update.jbuilder`
- `spec/requests/admin/api/v1/fleets/index_spec.rb`
- `spec/requests/admin/api/v1/fleets/show_spec.rb`
- `spec/requests/admin/api/v1/fleets/create_spec.rb`
- `spec/requests/admin/api/v1/fleets/update_spec.rb`
- `spec/requests/admin/api/v1/fleets/destroy_spec.rb`

Files to modify:
- `config/routes/admin/api/v1_routes.rb` — add `resources :fleets, only: %i[index show create update destroy]`

Permitted params: `name`, `fid`, `description`, `public_fleet`, `public_fleet_stats`, `discord`, `guilded`, `homepage`, `twitch`, `youtube`, `ts`, `rsi_sid`, `logo`, `background_image`

**Frontend:**

Files to create:
- `app/frontend/admin/composables/useFleetFilters.ts`
- `app/frontend/admin/components/Fleets/FilterForm/index.vue`
- `app/frontend/admin/components/Fleets/Form/index.vue`
- `app/frontend/admin/components/Fleets/Actions/index.vue`
- `app/frontend/admin/components/Fleets/Actions/Items.vue`

Files to modify:
- `app/frontend/admin/pages/fleets.vue` — restructure into list page (or create sub-pages)

---

### Step 9: User Actions (resend confirmation, password reset, login as)

**Backend:**

Files to modify:
- `app/controllers/admin/api/v1/users_controller.rb` — add `login_as`, `resend_confirmation`, `send_password_reset` actions
- `config/routes/admin/api/v1_routes.rb` — add `resend-confirmation` and `send-password-reset` member routes (login-as already exists)
- `config/locales/en/messages.yml` — add `send_password_reset` i18n keys

Files to create:
- `spec/requests/admin/api/v1/users/login_as_spec.rb`
- `spec/requests/admin/api/v1/users/resend_confirmation_spec.rb`
- `spec/requests/admin/api/v1/users/send_password_reset_spec.rb`

**Frontend:**

Files to modify:
- `app/frontend/admin/components/Users/Actions/Items.vue` — add buttons for resend confirmation, password reset, login as user

---

---

## Phase 2: Admin List Actions

All list pages and CRUD forms are implemented. The remaining work is wiring up row-level actions and global actions on each list page. Many action handlers currently just `console.info()` and need real implementations.

### Current State of Actions

| Resource | Actions Component | Edit | Delete | Sync/Reload | Other |
|----------|------------------|------|--------|-------------|-------|
| Models | `Models/Actions/Items.vue` | Link (works) | Stub | Stub | exchangeStoreImage (stub) |
| Manufacturers | `Manufacturers/Actions/Items.vue` | Link (works) | Stub | Stub | — |
| ModelPaints | `ModelPaints/Actions/Items.vue` | Link (works) | Stub | — | — |
| Users | `Users/Actions/Items.vue` | Link (works) | Stub | — | loginAs, resendConfirmation, sendPasswordReset (all work) |
| Components | None | — | — | — | — |
| Fleets | None | — | — | — | — |
| Vehicles | None | — | — | — | — |
| AdminUsers | None | — | — | — | — |

---

### Step 10: Models Global & Row Actions

Backend endpoints `reload_matrix`, `reload_scdata`, `reload_loaners`, `reload_paints` (collection) and `use_rsi_image`, `reload_one` (member) exist in the controller but are **not routed**.

**Backend:**

Files to modify:
- `config/routes/admin/api/v1_routes.rb` — add collection routes `reload-matrix`, `reload-scdata`, `reload-loaners`, `reload-paints` and member routes `use-rsi-image`, `reload-one`

Files to create:
- `spec/requests/admin/api/v1/models/reload_matrix_spec.rb`
- `spec/requests/admin/api/v1/models/reload_scdata_spec.rb`
- `spec/requests/admin/api/v1/models/use_rsi_image_spec.rb`
- `spec/requests/admin/api/v1/models/reload_one_spec.rb`

**Frontend:**

Files to modify:
- `app/frontend/admin/pages/models/index.vue` — wire `@click` handlers on the two reload buttons to call `reload_matrix` and `reload_scdata` API endpoints
- `app/frontend/admin/components/Models/Actions/Items.vue` — implement `sync` (calls `reload_one`), `exchangeStoreImage` (calls `use_rsi_image`), and `destroy` (calls delete mutation) using the generated API client + `displayConfirm`

---

### Step 11: Manufacturers Row Actions

Wire up `sync` and `destroy` stubs in `Manufacturers/Actions/Items.vue`.

**Frontend only** — backend `destroy` endpoint already exists. Determine if a sync action is applicable for manufacturers or if the button should be removed.

Files to modify:
- `app/frontend/admin/components/Manufacturers/Actions/Items.vue` — implement `destroy` using `displayConfirm` + delete mutation. Evaluate whether `sync` is needed.

---

### Step 12: ModelPaints Row Delete

Wire up `destroy` stub in `ModelPaints/Actions/Items.vue`.

**Frontend only** — backend `destroy` endpoint already exists.

Files to modify:
- `app/frontend/admin/components/ModelPaints/Actions/Items.vue` — implement `destroy` using `displayConfirm` + delete mutation

---

### Step 13: Users Row Delete

Wire up `destroy` stub in `Users/Actions/Items.vue`.

**Frontend only** — backend `destroy` endpoint already exists.

Files to modify:
- `app/frontend/admin/components/Users/Actions/Items.vue` — implement `destroy` using `displayConfirm` + delete mutation

---

### Step 14: Components List Actions

No action component exists yet. Backend CRUD is fully implemented.

**Frontend:**

Files to create:
- `app/frontend/admin/components/Components/Actions/index.vue` — wrapper (follows `Models/Actions/index.vue` pattern)
- `app/frontend/admin/components/Components/Actions/Items.vue` — edit link, delete button with tooltips

Files to modify:
- `app/frontend/admin/pages/components/index.vue` — add `#actions` slot to BaseTable

---

### Step 15: Fleets List Actions

No action component exists yet. Backend CRUD is fully implemented.

**Frontend:**

Files to create:
- `app/frontend/admin/components/Fleets/Actions/index.vue` — wrapper
- `app/frontend/admin/components/Fleets/Actions/Items.vue` — edit link, delete button with tooltips

Files to modify:
- `app/frontend/admin/pages/fleets.vue` — add `#actions` slot to BaseTable

---

### Step 16: AdminUsers List Actions

No action component exists yet. Backend CRUD is fully implemented.

**Frontend:**

Files to create:
- `app/frontend/admin/components/AdminUsers/Actions/index.vue` — wrapper
- `app/frontend/admin/components/AdminUsers/Actions/Items.vue` — edit link, delete button with tooltips

Files to modify:
- `app/frontend/admin/pages/admins.vue` — add `#actions` slot to BaseTable

---

### Step 17: Vehicles List Actions

Vehicles currently only have a read-only `index` endpoint. Actions may be limited.

**Investigation needed:**
- Determine what actions are appropriate for vehicles (view owner, link to model, delete?)
- May need backend endpoints if admin should be able to delete vehicles

**Frontend (if applicable):**

Files to create:
- `app/frontend/admin/components/Vehicles/Actions/index.vue` — wrapper
- `app/frontend/admin/components/Vehicles/Actions/Items.vue` — view/link buttons

Files to modify:
- Vehicles list page — add `#actions` slot

---

## Progress

| Step | Status |
|------|--------|
| Step 1: Components List Page | Done |
| Step 2: Models Create Page | Done |
| Step 3: Manufacturers Create & Edit | Done |
| Step 4: Components Create & Edit | Done |
| Step 5: Model Paints Create & Edit | Done |
| Step 6: Users Edit | Done |
| Step 7: Admin Users Management | Done |
| Step 8: Fleets Management | Done |
| Step 9: User Actions | Done |
| Step 10: Models Global & Row Actions | Done |
| Step 11: Manufacturers Row Actions | Done |
| Step 12: ModelPaints Row Delete | Done |
| Step 13: Users Row Delete | Done |
| Step 14: Components List Actions | Done |
| Step 15: Fleets List Actions | Done |
| Step 16: AdminUsers List Actions | Done |
| Step 17: Vehicles List Actions | Skipped (read-only) |

---

## After Each Backend Step

Run these commands after adding backend endpoints:
```bash
bundle exec standardrb --fix        # Fix Ruby linting
rspec spec/requests/admin/           # Run admin API specs
./bin/generate-schema                # Regenerate OpenAPI schema
```

Then regenerate the TypeScript API client so frontend can use the new endpoints.

## After Each Frontend Step

```bash
pnpm lint                            # Fix frontend linting
pnpm test                            # Run frontend tests
```

## Key Reference Files

| Purpose | Path |
|---------|------|
| List page pattern | `app/frontend/admin/pages/models/index.vue` |
| Edit form pattern | `app/frontend/admin/pages/models/[id]/edit/index.vue` |
| Form component | `app/frontend/admin/components/Models/Form/index.vue` |
| Filter composable | `app/frontend/admin/composables/useModelFilters.ts` |
| Update mutation | `app/frontend/admin/composables/useModelUpdateMutation.ts` |
| Backend CRUD controller | `app/controllers/admin/api/v1/models_controller.rb` |
| Request spec pattern | `spec/requests/admin/api/v1/models/update_spec.rb` |
| Jbuilder views | `app/views/admin/api/v1/models/` |
| Routes | `config/routes/admin/api/v1_routes.rb` |
| Base controller | `app/controllers/admin/api/base_controller.rb` |
