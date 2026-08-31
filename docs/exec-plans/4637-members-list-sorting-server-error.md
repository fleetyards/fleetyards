# Server Error Members List

## Goal
Sorting any list in the app sends a query the API accepts, so clicking a sortable
table header sorts the list instead of rendering the ServerError page.

## Context
Sorting the fleet member list returns **400 Bad Request**, which `FilteredList`
renders as the generic `ServerError` component — hence the "Server Error"
report. Reproduced locally against `/api/v1/fleets/:slug/members`:

```
q[s]=username asc     -> 400 {"error":"Request validation failed",
  "details":["Invalid query parameter 'q': object property at `/s` is a disallowed additional property"]}
q[sorts]=username asc -> 200
```

The chain:

1. `useTableSorting` writes the active sort into the **route** query as `?s=username asc`.
2. `useFilters.getQuery()` spreads the whole `route.query` into the API's `q`
   object, so `s` is sent as `q[s]`.
3. The endpoint's query schema declares only `sorts` and sets
   `additionalProperties: false`. openapi-ruby request validation is
   `:enabled` globally (`config/initializers/openapi_ruby.rb`), production
   included, so the request is rejected before the controller runs.
4. `FleetMemberFiltersConcern` does not permit `:s` and the controller never
   calls `normalize_sort_params`, so even past the validator the sort would be
   silently dropped in favour of `DEFAULT_SORTING_PARAMS`.

`410fc1971 "fix(api): support s param for sorting across all endpoints"`
(2026-04-25) established the fix pattern but only applied it to three schemas:
`fleet_vehicle_query`, `hangar_query`, `model_query`. Of 25 query schemas that
accept `sorts`, only those 3 also accept `s`.

Resolves #4637

## Decisions

### D1 — Fix on the API side, not in `useFilters`
The tempting one-line fix is to have `getQuery()` translate `s` into `sorts`.
Rejected: `getQuery()` serves double duty — `debouncedFilter` feeds its result
straight into `router.replace({ query: ... })`. Renaming the key there would
rewrite the browser URL to `?sorts=…`, which `useTableSorting` (reads
`route.query.s`) no longer recognises, breaking the sort indicator and every
shared/bookmarked sort link. The URL contract stays `s`; the API learns to
accept it.

### D2 — Apply the rule uniformly: every schema that accepts `sorts` accepts `s`
Only 8 pages leak `s` into `q` today (see Key files). Most admin pages are
unaffected because they map `route.query.s` to `q.sorts` themselves and
`filters.value` strips `s`. Two admin pages (`models`, `vehicles`) do leak it,
because they spread `...getQuery()` *and* pass an explicit `sorts`.

Still applying `s` to all schemas that accept `sorts`, rather than only the 8
reachable ones, because:
- The invariant "`s` is the alias for `sorts`" is then true everywhere, so this
  bug class cannot come back the next time a page starts spreading `route.query`.
- It is what the earlier commit's title already promised.
- A per-endpoint exception list is invisible in the frontend and would be
  re-discovered as a production 400.

Schemas with **no** `sorts` (e.g. `inventory_stock_query`) are left alone — they
have no sort surface, and none of them receive a leaked `s`.

### D3 — Permit and normalize wherever the schema gains `s`
Adding `s` to a schema alone only stops the 400; the sort would still be
ignored. Every controller whose schema gains `s` also gets `:s` permitted and
`normalize_sort_params` called before `sorting_params`, matching
`fleet_vehicle_filters_concern` / `hangar_inventories_controller`. Exception:
controllers that never read `q[s]` because the frontend already sends an
explicit `sorts` (admin `models`, `vehicles`) still get it, so the param means
the same thing on every endpoint.

### D4 — Leave the permit lists explicit, do not switch to ParamsHelper
`HangarFiltersConcern` derives its permit list straight from the schema
(`ParamsHelper.new("v1/schema.yaml").to_params("HangarQuery")`), which is why
the hangar endpoints never drifted. That is the durable answer to this bug
class, but converting 20 controllers to it is a refactor with its own failure
mode (a stale committed yaml silently narrows strong params). Kept explicit
here; noted as the follow-up.

## What changed

### Phase 1 — Fleet members (the reported bug)
1. `V1::Schemas::Queries::FleetMemberQuery` — add `s` mirroring `sorts`
   (`anyOf` of array-of-`FleetMembershipSortEnum` and the bare enum).
2. `FleetMemberFiltersConcern` — permit `:s`.
3. `Api::V1::FleetMembersController#index` — call
   `normalize_sort_params(member_query_params)` before `sorting_params`.
4. Regression tests in `test/integration/api/v1/fleets_members_index_test.rb`
   for each of the four sortable columns via `q[s]`, asserting 200 and order.

### Phase 2 — The other endpoints the frontend actually breaks
Same three-part change for:
- `V1::Schemas::Queries::FleetInventoryItemQuery` (fleet logistics, fleet inventory detail)
- `V1::Schemas::Queries::HangarInventoryItemQuery` (hangar inventories, inventory detail)
- `V1::Schemas::Queries::HangarInventoryQuery`
- `V1::Schemas::Queries::InventoryItemQuery` (ship cargo page)
- `Admin::V1::Schemas::Queries::ModelQuery` (admin models list)
- `Admin::V1::Schemas::Queries::VehicleQuery` (admin vehicles list)

The four inventory controllers already permit `:s` and call
`normalize_sort_params`; only their schemas need the addition.

### Phase 3 — Uniform sweep of the remaining `sorts` schemas
Add `s` to the remaining schemas that accept `sorts` and give their controllers
`:s` + `normalize_sort_params`: `notification_query`, and the admin
`admin_fleet_member`, `admin_notification`, `commodity`, `component`,
`equipment`, `fleet`, `funding_goal`, `image`, `manufacturer`,
`model_module_package`, `model_paint`, `sc_data_unlisted_model`,
`supporter_contribution` queries.

### Phase 3b — Two further bugs the new tests exposed
1. `normalize_sort_params` only deleted `s` when it was the key that filled
   `sorts` in. With both present, `||=` short-circuits, `s` survives into
   `ransack`, and ransack reads `s` itself — so the unvalidated `s` outranked
   the whitelisted `sorts`. It now always deletes `s`.
2. `/fleets/:slug/stats/members` returned a **500** for any sort param:
   `members_by_role` is a grouped count, so an ORDER BY on `users.username`
   leaves an ungrouped column in the query and Postgres rejects it
   (`PG::GroupingError`). Both stats controllers now strip `sorts`/`s` the way
   `model_counts` already did. This was live before this change — `sorts` alone
   was enough to trigger it.

### Phase 4 — Schema regeneration and diff review
1. Regenerate `swagger/v1/schema.yaml` and `swagger/admin/v1/schema.yaml`.
2. Regenerate the TS clients so `lint:ts` stays clean.
3. Review the `oasdiff` result — additive optional properties only, so
   `api-schema-breaking` must stay green.

## Intent Verification

- [ ] **All four member columns sort** — `/fleets/:slug/members/?s=username asc`,
      `rsiHandle asc`, `acceptedAt asc`, `lastActiveAt asc` each return 200 and
      the documented order, asc and desc.
- [ ] **The invites list sorts** — same endpoint, `variant="invites"` page.
- [ ] **No page leaks a rejected param** — for every `getQuery()` call site, the
      endpoint's schema accepts `s`.
- [ ] **`s` and `sorts` agree** — where both are sent, `sorts` wins (unchanged
      `normalize_sort_params` semantics: `s` only fills in when `sorts` is absent).
- [ ] **Schema diff is additive** — `api-schema-breaking` green.
- [ ] **Ruby + TS lint and the touched integration tests pass.**

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/composables/useTableSorting.ts` | Writes `?s=<field> <dir>` into the route |
| `app/frontend/shared/composables/useFilters.ts` | `getQuery()` spreads `route.query` into the API `q` — the leak |
| `app/frontend/shared/components/FilteredList/index.vue` | Renders `ServerError` for any non-403 error, masking the 400 |
| `app/api_components/v1/schemas/queries/fleet_member_query.rb` | Rejects `q[s]` via `additionalProperties: false` |
| `app/api_components/v1/schemas/queries/fleet_vehicle_query.rb` | Reference for the `s` declaration |
| `app/controllers/concerns/fleet_member_filters_concern.rb` | Strong params for the member list |
| `app/controllers/api/v1/fleet_members_controller.rb` | Missing `normalize_sort_params` |
| `app/helpers/ransack_helper.rb` | `normalize_sort_params` / `sorting_params` |
| `config/initializers/openapi_ruby.rb` | `request_validation = :enabled` — why this is a 400 in production |
| `test/integration/api/v1/fleets_members_index_test.rb` | Existing `sorts` coverage to extend with `s` |

**Pages that leak `s` into `q`** (via `getQuery()`):
`fleets/[slug]/members/index.vue`, `fleets/[slug]/members/invites.vue`,
`fleets/[slug]/logistics/index.vue`,
`fleets/[slug]/logistics/inventories/[inventory].vue`,
`hangar/inventories/index.vue`, `hangar/inventories/[inventory].vue`,
`hangar/[id]/cargo.vue`, `admin/pages/models/index.vue`,
`admin/pages/vehicles/index.vue`. (`ships/index.vue`, `hangar/index.vue` and
`Fleets/ShipsList` also leak it, but their schemas already accept `s`.)

## Not in scope (deferred)
- **Making `FilteredList` distinguish 400 from 5xx** — a 400 rendering as
  "Server Error" is why this took a user report to surface, but changing the
  error surface is its own UX decision.
- **Retiring `s` in favour of `sorts` end to end** — would change every
  bookmarkable sort URL.
- **Schemas with no `sorts`** — no sort surface, no leaked `s`.
- **A CI check that every `getQuery()` call site's schema accepts `s`** — worth
  having, but needs a frontend↔schema mapping that does not exist yet.
- **Deriving permit lists from the schema everywhere** (see D4) — the real cure
  for permit-vs-schema drift.
- **`ModelUpgradeQuery`** — its controller permits and reads `sorts`, but the
  schema declares no sorting at all, so `q[sorts]` 400s there today. Nothing in
  the UI sorts that list and there is no `ModelUpgradeSortEnum` to reference, so
  fixing it means designing the sort surface, not adding a param.

## Discovery Log

- **2026-08-31** Reproduced the failure as a 400 from openapi-ruby request
  validation, not a 500. Traced the leak to `useFilters.getQuery()` spreading
  `route.query`. Audited all 25 `sorts`-accepting schemas: 22 reject `s`.
  Established that most admin pages are unaffected (they map `s` to `sorts`
  themselves); `admin/models` and `admin/vehicles` are not. Rejected fixing
  `getQuery()` because it also builds the browser URL.
- **2026-08-31** Implemented. The new "prefers sorts over s" test failed and
  exposed the `normalize_sort_params` short-circuit; the stats probe exposed a
  pre-existing 500 on `/fleets/:slug/stats/members` for any sort param. Both
  fixed. Generated clients live under `.gitignore`, so only the two
  `swagger/*.yaml` files carry the regeneration. 22 schemas gained `s`
  (+116 lines of yaml, all additive optional properties).

## Progress
- [x] Phase 1 — Fleet members
- [x] Phase 2 — Other reachable endpoints
- [x] Phase 3 — Uniform sweep
- [x] Phase 3b — `normalize_sort_params` and the member stats 500
- [x] Phase 4 — Schema regeneration and diff review
