# Admin UI for blueprints

## Goal

An admin Blueprints section — a filterable list of all 1,607 recipes and a detail page per
recipe — that answers "what did the last load produce, and what did it get wrong?" without
offering any way to type over it.

## Context

Resolves #5032.

The public blueprint catalogue shipped in #5031 (issue #4988). Commodities, components and
equipment each have an admin section; blueprints have none, so a load can only be inspected
through the public site or a Rails console.

Blueprints are **loader-owned and build-fact layered**. `blueprints` holds the identity;
`blueprint_builds` holds what each game build said (`name`, `craftable_type`, `craftable_id`,
`category_ref`, `craft_time`, `slot_count`), and the slots, options, modifiers and sources all
hang off the build (`app/models/blueprint_build.rb:43-51`). A load replaces the facts for its
build, so anything typed into a fact column is gone at the next parse.

That makes this a **read-and-inspect** surface, not a CRUD one.

## Decisions

### D1 — Nothing is editable; no migration

**Chosen by the user over `hidden` and over `hidden` + a curator note.**

The admin section is read-only: index, detail, filters. No create, no update, no destroy, no
input schema, no form, no new column on `blueprints`.

What this costs, stated plainly so the follow-up is cheap to open: `Blueprint` has no `hidden`
column while `Component` does (`db/schema.rb:415`), so there is still **no way to keep a recipe
out of the public catalogue**, and nothing carries a human note about the five recipes whose
output resolves to nothing. Both were on the table and both were declined for this pass.

If `hidden` is wanted later, the pattern is fixed and recorded here so it need not be
rediscovered: a boolean on **both** `blueprints` and `blueprint_builds`, added to
`BlueprintBuild::FACTS` and `::FILTERABLE` and held **out of `READ_THROUGH`** — Blueprint's
read-through readers deliberately do not fall back to the column
(`app/models/blueprint.rb:342-355`), and Component sidesteps exactly this by excluding `hidden`
from `READ_THROUGH` (`app/models/component_build.rb:75`).

### D2 — A new `blueprints` privilege, in the `ship_data` group

`Admin::BlueprintPolicy < BasePolicy` with `resource_access = [:blueprints]`, and `blueprints`
added to `AdminUser::RESOURCE_ACCESS[:ship_data]` (`app/models/admin_user.rb:53-58`) beside
`components equipment commodities`.

Not optional and not deferrable: `AdminUserPrivilegesTest` fails if a policy names a privilege
absent from that list, and the frontend `access: ["blueprints"]` guard reads
`AdminUserResourceAccessEnum`, which is generated from the admin schema — so the enum has no
`blueprints` member until the Ruby list has one.

Rejected: reusing `components`. A blueprint is not a component, and the three sibling
catalogues each carry their own privilege.

### D3 — "Output resolves to nothing" becomes a real filter, mirroring `with_known_source`

The two gaps the issue wants visible are asymmetric today:

| gap | rows | how it is modelled |
|---|---|---|
| no stated source | 901 | first-class end to end — `Blueprint.with_known_source` (`blueprint.rb:116-122`), `source_unknown?`, the `withKnownSource` param, `sourceUnknown` in the payload |
| output resolves to nothing | 5 | **nothing** — no scope, no count, no predicate, no API surface; only code comments and the `:without_craftable` factory trait |

So this plan adds `Blueprint.with_craftable(flag, source, current_only:)` beside
`with_known_source`, reading `craftable_id` through the build the same way, plus a
`craftableMissing` boolean on the admin list payload.

It is **applied by the controller, not registered as a ransack scope** — for the reason already
documented at `blueprint.rb:225-244`: ransack coerces `"false"` to `false` and then only applies
a scope when the value is truthy, so a boolean ransack scope can only ever mean "on", and
`withKnownSource=false` once returned the whole catalogue instead of the 901.

### D4 — Detail shows which build each fact came from

`current_version` decides what the public sees and a PTU load is a separate `blueprint_builds`
row. The detail payload therefore carries the served build's `version` and `environment`, the
`retired` flag (`build.blank?`), and — when the served build is a fallback rather than the
current one — says so. `Blueprint#facts` is `build || last_build` (`blueprint.rb:331-333`), and
that distinction is invisible on the public page.

### D5 — Show by `:id`, not `:slug`

The public API uses `param: :slug` (`config/routes/api/blueprints_routes.rb:4`). Every admin
section uses `:id`, the admin list rows carry `id`, and the breadcrumb/route-name conventions
(`admin-blueprint-show`) assume it. Follow the admin convention.

### D6 — No edit tabs, so no `[id]/edit/` tree

Components has three edit tabs (base data, prices, history); equipment has two; commodities has
one. Blueprints has none — there is nothing to edit, blueprints carry no `item_prices`, and
`Blueprint` has no `has_paper_trail`, so a history tab would render an empty list. `[id].vue`
loads the record and renders the detail itself; no child routes, no `TabNavView`.

## What changed

### Phase 1 — Admin API

1. `blueprints` in `AdminUser::RESOURCE_ACCESS[:ship_data]`; `app/policies/admin/blueprint_policy.rb`.
2. `Blueprint.with_craftable(flag, source, current_only:)` beside `with_known_source`, routed
   through `readable_builds` like every other list scope (`blueprint.rb:205-214`).
3. `Blueprint.craftable_type_filters` and `Blueprint.org_filters` as `Filter` PORO class methods,
   matching `Component.class_filters` (`component.rb:547`). `Blueprint.material_filters` already
   exists (`blueprint.rb:310`).
4. `Admin::Api::V1::BlueprintsController` — `index` and `show` only, plus
   `craftable_type_filters`, `material_filters`, `org_filters` on the collection, each rendering
   `api/shared/filters`. `index` follows the components shape: `authorize!` →
   `normalize_sort_params` → `sorting_params` → `authorized_scope(Blueprint.with_facts(false))`
   → `.ransack(...)` → kaminari. The three build-reading filters (`fromOrg`,
   `consumingCommodity`, `withKnownSource`) and the new `withCraftable` are stripped out of the
   ransack hash and applied by hand, exactly as `Api::V1::BlueprintsController#source_filters`
   does (`:62-74`).
5. Routes: a `resources :blueprints, only: %i[index show]` block in
   `config/routes/admin/api/v1_routes.rb`, alongside components/equipment/commodities.
6. Views `app/views/admin/api/v1/blueprints/{index,show,_blueprint,_base}.jbuilder`. `_base`
   carries the list fields plus `craftableMissing`, `sourceUnknown`, `retired` and the build
   provenance from D4; `show` adds the slots with their options, quality ramps and modifiers,
   and the sources with org and standing band. Cache key on
   `[..., blueprint, blueprint.facts, ScData::Source.current]`, as the public partial does.

### Phase 2 — Schema and generated client

1. `app/api_components/admin/v1/schemas/blueprint.rb` (extends `Shared::V1::Schemas::Blueprint`,
   adds the admin-only fields), `queries/blueprint_query.rb`, `sorts/blueprint_sort_enum.rb`
   from `Blueprint::ALLOWED_SORTING_PARAMS`. **No input schema** — D1.
2. `test/integration/admin/api/v1/blueprints_test.rb` plus one file per filter endpoint. These
   are the OpenAPI source of truth, not just tests: operations must be declared in alphabetical
   order, and `tags "Blueprints"` is what decides the orval output folder.
3. `bin/generate-schema`, then commit `swagger/admin/v1/schema.yaml` and the regenerated
   `app/frontend/services/fyAdminApi/`.

### Phase 3 — Admin pages

1. `app/frontend/admin/pages/blueprints.vue` (router-view shell) and
   `blueprints/{routes.ts,index.vue,[id].vue}`.
2. `index.vue` on the canonical list shape: `usePagination` → `useBlueprintFilters` →
   `useBlueprints(params)` → `FilteredList` → `BaseTable`, with the search input and no create
   button teleported into `#header-left` / `#header-right`.
3. `app/frontend/admin/components/Blueprints/FilterForm/index.vue` — name search, craftable type,
   material, org, and the two boolean filters that are the point of the issue: known source and
   output resolved. Any `base/*Select` wrappers the filter endpoints need.
4. `[id].vue` — `useBlueprint(id)` inside `AsyncData`, breadcrumbs, then a `DetailList` header
   (output, craft time, slot count, build provenance) and the slots/sources panels.

### Phase 4 — Nav, access and i18n

1. Top-level entry in `app/frontend/admin/pages/routes.ts` with `path: "/blueprints/"` and
   `access: ["blueprints"]`, positioned so it lands beside components in the nav.
2. `"/blueprints/"` added to the `catalogue` group's `paths` in
   `app/frontend/admin/components/Navigation/index.vue:58` — matched by exact path string
   including the trailing slash; without it the section renders as its own top-level row.
3. Keys in **all seven** locales under `app/frontend/translations/`: `nav.admin.blueprints.*`,
   `title.admin.blueprints.*`, `headlines.admin.blueprints.*`, `labels.filters.blueprints.*`,
   `placeholders.filters.blueprints.*`. `meta.title` needs both namespaces — `nav.*` labels the
   tab, `title.*` the document.
4. The `blueprints` privilege label, also in all seven locales — privilege labels have shipped as
   "translation missing" before because the label list was not extended with the privilege.

## Intent Verification

- [ ] **The catalogue is listed** — the admin list shows all recipes, paginated and sortable, and
      filters by what they make, the material they consume, and whether anything hands them out.
- [ ] **The five unresolved outputs are reachable in one click** — a filter isolates recipes whose
      output resolves to nothing, and the list says so per row rather than rendering a blank.
- [ ] **The 901 without a source are reachable in one click** — and `withKnownSource=false`
      returns 901, not the whole catalogue.
- [ ] **The recipe is fully visible** — detail shows every slot with its options, quality gates
      and stat ramps, and every source with its org and standing band.
- [ ] **Provenance is stated** — detail names the build version and environment the facts came
      from, and marks a retired recipe as retired.
- [ ] **Nothing is writable** — no create, update or destroy route, action or form exists.
- [ ] **Access is gated** — an admin without the `blueprints` privilege gets 403 from the API and
      no nav entry.
- [ ] **Schema is clean** — `bin/generate-schema` produces no diff, and `api-schema-lint` and
      `api-schema-breaking` pass.

## Key files

| File | Role |
|------|------|
| `app/controllers/admin/api/v1/blueprints_controller.rb` | new — index, show, three filter endpoints |
| `app/controllers/admin/api/v1/components_controller.rb` | the template to follow |
| `app/controllers/api/v1/blueprints_controller.rb:62-74` | how the hand-applied boolean filters work |
| `app/policies/admin/blueprint_policy.rb` | new |
| `app/models/admin_user.rb:53-58` | `RESOURCE_ACCESS` — needs `blueprints` |
| `app/models/blueprint.rb` | `with_known_source`, `readable_builds`, `material_filters`; gains `with_craftable` |
| `app/models/blueprint_build.rb` | `FACTS`, `READ_THROUGH`, `FILTERABLE` |
| `app/views/admin/api/v1/blueprints/` | new — index, show, `_blueprint`, `_base` |
| `config/routes/admin/api/v1_routes.rb:91-105` | where the resources block goes |
| `app/api_components/admin/v1/schemas/` | `blueprint.rb`, `queries/`, `sorts/` |
| `app/api_components/shared/v1/schemas/blueprint*.rb` | already shared into the admin document |
| `test/integration/admin/api/v1/blueprints_test.rb` | new — also the OpenAPI source |
| `app/frontend/admin/pages/blueprints/` | new — shell, routes, index, detail |
| `app/frontend/admin/components/Blueprints/FilterForm/` | new |
| `app/frontend/admin/components/Navigation/index.vue:58` | `GROUPS` — `catalogue` needs `/blueprints/` |
| `app/frontend/translations/*/{nav,title,headlines,labels,placeholders}.json` | seven locales |

## Traps

- **The local dump carries 0 blueprints.** The loader has never run against it, so every page
  built against local data renders an empty list until blueprints are loaded. Every count in
  this plan comes from the parsed tree, not from a database.
- **`craftable` cannot be a ransackable association.** Ransack computes an association's class to
  build the join and a polymorphic one has none. `craftable_type` is filtered as a plain column.
- **A boolean ransack scope can only ever mean "on"** — D3.
- **The Blueprint TS models already exist** in `app/frontend/services/fyAdminApi/models/`, because
  `shared/v1` schemas are scoped into both documents. There is no `services/blueprints/` and no
  `/blueprints` path in the admin schema until Phase 2 runs.
- **`bin/generate-schema` needs a server restart** when a new param or property is added, or the
  request validator 400s.
- **Admin runs on `admin.fleetyards.test`**, and admin pages carry no `data-test` ids today — any
  test selector has to be added by hand.

## Not in scope (deferred)

- **`hidden` on `Blueprint`** — declined in D1. There is still no way to keep a recipe out of the
  public catalogue; the migration and the fact-layering recipe are recorded in D1 for whoever
  picks it up.
- **A curator note** — declined in D1.
- **Correcting recipe data.** The game files are the source; a wrong recipe is a parser or loader
  fix, not an admin edit.
- **Counted commodities** — #4988 phase 5, a loader change rather than an admin one.
- **Edit tabs (prices, history)** — D6.

## Discovery Log

- **2026-09-19** Research across the components admin backend, the admin frontend and the
  blueprint domain model. Three findings shaped the plan: the "no stated source" gap is modelled
  end to end while "output resolves to nothing" has no surface at all (D3); the Blueprint admin
  TS models already exist but no admin endpoint does; and `Blueprint`'s read-through readers
  deliberately skip the column fallback, which is what makes a future `hidden` non-obvious (D1).
  D1 put to the user, who chose a read-only admin with no migration.
- **2026-09-19** Built, all four phases. Three things worth recording:
  - **`json.partial! "...", blueprint:` is a syntax error in a jbuilder template.** Ruby's
    hash value omission reads the value from the next line, and the next line in a template is
    another `json.` call — the error is reported against that line, not against the omission.
    The public `_blueprint.jbuilder` gets away with it only because `end` follows.
  - **The recipe block is now a partial.** `api/v1/blueprints/_recipe` renders the cost tree and
    the sources for both the public and the admin detail response, rather than the admin one
    holding a second copy that drifts. The extraction produces byte-identical public output.
  - **`bin/generate-schema` reordered `components.parameters` in both documents** — the known
    macOS-vs-CI flip. Reverted by hand; the committed diff is additions only.

## Progress
- [x] Phase 1 — Admin API
- [x] Phase 2 — Schema and generated client
- [x] Phase 3 — Admin pages
- [x] Phase 4 — Nav, access and i18n
