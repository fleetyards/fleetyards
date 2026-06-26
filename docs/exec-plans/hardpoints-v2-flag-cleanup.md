# Exec Plan: Remove the `hardpoints-v2` feature flag and dead legacy code path

## Goal & scope

Make the **v2 hardpoints** implementation (`Hardpoint` model → `model.hardpoints`)
the unconditional path, and delete the now-dead legacy branches that were gated
behind `feature_enabled?("hardpoints-v2")` / `isFeatureEnabled('hardpoints-v2')`.

**In scope**
- Remove every `hardpoints-v2` flag check (backend + frontend) and the `else`/legacy
  branch each one guards.
- Delete the dead legacy views/components reachable only via the old path.
- Migrate the existing hardpoint tests (which currently exercise the legacy path) to
  the v2 path, and add the v2 `Hardpoint` test factory they need.
- Optional final data migration to remove the `hardpoints-v2` record from Flipper.

**Explicitly out of scope** (decided 2026-06-25)
- Keep the `ModelHardpoint` model and the `model_hardpoints` DB table. They are still
  referenced by `model_hardpoint_loadout`, `vehicle_loadout`, `component`, and the
  shared `model_hardpoint_*_enum` api_components. Tearing those out is a separate,
  riskier migration.

## ⚠️ Pre-merge verification (do this first)

The v2 path is currently **untested** — no test enables `hardpoints-v2`, so every
existing hardpoint test runs the legacy path by default. That also means we have no
in-repo signal that v2 is production-ready.

**Before merging**, confirm `hardpoints-v2` is globally enabled in production Flipper
(i.e. v2 is what real users already get). If it is *not* fully rolled out, this cleanup
is premature — stop and revisit. This plan assumes "yes, v2 is the live path for
everyone."

## Call-site inventory

### Backend — flag checks to remove

1. `app/controllers/api/v1/models_controller.rb` — `hardpoints` action (~L118–138)
   - Two `feature_enabled?("hardpoints-v2")` branches.
   - Keep only: `scope = model.hardpoints.includes(:component)` and
     `render "api/v1/models/hardpoints"`.
   - Drop: the `model.model_hardpoints.includes(:component).undeleted` else branch and
     the `render "api/v1/models/hardpoints_old"` else branch.

2. `app/controllers/admin/api/v1/model_hardpoints_controller.rb` — branches on
   `hardpoints_v2?` in `index`, `create`, `show`, `update`, `destroy`, `set_hardpoint`.
   - Collapse each to the v2 branch only.
   - Delete the now-dead private helpers: `hardpoints_v2?`, `legacy_hardpoint_params`,
     `legacy_query_params`.
   - Keep `v2_hardpoint_params` / `v2_query_params` (rename optional — leave as-is to
     minimise churn).
   - Route stays: `resources :model_hardpoints, path: "model-hardpoints"`
     (`config/routes/admin/api/v1_routes.rb:70`). Controller keeps its name; it just
     serves `Hardpoint` records exclusively now.

### Backend — dead files to delete

3. `app/views/api/v1/models/hardpoints_old.jbuilder` — only reachable via the removed
   else branch.

### Backend — orphaned after cleanup (decision needed, default = keep)

4. `app/policies/admin/model_hardpoint_policy.rb` — after the legacy admin branches go,
   its only references disappear. It is tied to the `ModelHardpoint` model we are
   keeping. **Default: leave it** (cheap, avoids touching the kept model's policy
   surface). Flag for reviewer; remove only if you want zero orphans.

### Frontend — flag checks + dead components

5. `app/frontend/frontend/components/Models/Hardpoints/index.vue`
   - Remove `v-if="isFeatureEnabled('hardpoints-v2')"` on `<Hardpoints>` and the
     `<OldHardpoints v-else>` sibling (L23–24).
   - Remove the `OldHardpoints` import (L9) and, if `isFeatureEnabled` is now unused in
     this file, its `useFeatures()` usage.
   - Delete dead component: `app/frontend/frontend/components/Models/Hardpoints/old.vue`.

6. `app/frontend/frontend/pages/compare.vue`
   - Remove `v-if="isFeatureEnabled('hardpoints-v2')"` on `<CompareHardpoints>` and the
     `<CompareHardpointsOld v-else>` block (L112–120).
   - Remove the `CompareHardpointsOld` import (L19); drop `isFeatureEnabled`/`useFeatures`
     if now unused in this file.
   - Delete dead component dir:
     `app/frontend/frontend/components/Compare/Models/HardpointsOld/`.

### Tests — migrate from legacy to v2

These currently pass because the flag defaults off (legacy path). After the change they
will run the v2 path and break unless migrated.

7. **New**: `test/factories/hardpoints.rb` — a `:hardpoint` factory for the v2 model
   (`parent_type: "Model"`, `parent: model`, `component`, `sc_name`, `source`, etc.), plus
   a `:model` trait (e.g. `:with_v2_hardpoints`) that builds `hardpoints` instead of
   `model_hardpoints`. Mirror the existing `test/factories/model_hardpoints.rb` shape
   against the `Hardpoint` columns (see `db/schema.rb` `create_table "hardpoints"`).

8. `test/integration/api/v1/models_hardpoints_test.rb`
   - `create(:model, :with_hardpoints)` → v2 trait; assert against `model.hardpoints` and
     the `hardpoints.jbuilder` response shape (not `model_hardpoints` / `hardpoints_old`).

9. `test/integration/admin/api/v1/model_hardpoints_test.rb`
   - `valid_body` uses legacy params (`name`, `key`, `hardpointType`, `group`, `modelId`).
     The v2 `create` maps `name`→`sc_name` and `model_id`→`parent_id`, but `key` /
     `hardpointType` / `group` differ and the response renders `hardpoints/show`. Rework
     `valid_body` and the list/show/update/destroy expectations to the v2 contract.
   - Confirm `create(:admin_user, resource_access: [:model_hardpoints])` still authorises
     `Admin::HardpointPolicy` (the v2 policy). If the policy keys on a different
     `resource_access` symbol, update the fixture accordingly.

10. `test/integration/admin/api/v1/model_hardpoint_loadouts_test.rb` — verify it does not
    transitively depend on the legacy hardpoints index/create. Likely unaffected (loadouts
    keep using `ModelHardpoint`), but run it to be sure.

### Flipper feature record (optional, last)

11. The `hardpoints-v2` gate lives in the `flipper_*` tables, not in code. After code no
    longer references it, optionally add a data migration to remove it:
    `Flipper.remove(:hardpoints_v2)` / `Flipper.remove("hardpoints-v2")` (match the exact
    stored name). Low priority; an orphaned flag is harmless but tidy to drop.

## Step sequence (commits)

1. `refactor(hardpoints): make v2 the unconditional path in models API` — models_controller
   + delete `hardpoints_old.jbuilder`.
2. `refactor(hardpoints): drop legacy branch from admin hardpoints controller` —
   admin controller + dead private helpers.
3. `refactor(hardpoints): remove hardpoints-v2 flag from frontend` — both Vue files +
   delete `old.vue` and `HardpointsOld/`.
4. `test(hardpoints): cover v2 path` — new `:hardpoint` factory + migrate the two
   integration tests.
5. *(optional)* `chore(hardpoints): remove hardpoints-v2 flipper feature` — data migration.

Keep commits 1–3 behaviour-preserving for users already on v2; commit 4 is what proves it.

## Verification

- `bin/rails test test/integration/api/v1/models_hardpoints_test.rb
  test/integration/admin/api/v1/model_hardpoints_test.rb
  test/integration/admin/api/v1/model_hardpoint_loadouts_test.rb`
- `bundle exec standardrb` on all changed Ruby files.
- Frontend: `pnpm lint` / typecheck; confirm no dangling imports of the deleted
  components. Build the frontend to catch missing-module errors.
- Grep guard: `grep -rn "hardpoints-v2\|hardpoints_old\|OldHardpoints\|HardpointsOld\|hardpoints_v2?" app/ test/`
  should return nothing (except possibly the optional Flipper migration).

## Risks

- **v2 untested today** → the test migration (step 4) is the real work and the real risk;
  budget for it, don't treat this as a pure deletion.
- **Admin v2 create contract** differs from legacy params; the compatibility mapping in
  `v2_hardpoint_params` is partial. Expect to adjust request bodies and the schema the
  admin tests assert against.
- **Schema generation**: removing the legacy admin path may change the documented admin
  hardpoints operation. If so, update via `app/api_components` + `./bin/generate-schema`
  (never edit `schema.yaml` directly), then format + lint.
