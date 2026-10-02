# Public fleet directory for verified fleets

Working plan for #5291. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A public, paginated, searchable and filterable directory of verified, public fleets, on the API and in the frontend. Each fleet's activity, language, commitment, role play and recruiting status are synced daily from its RSI org. Managers set the alignment and can opt the fleet out.

## Open questions

- None right now.

## What changed

### Phase 1: Data model
1. Migration on `fleets`:
   - `listed` boolean nullable (no default; `nil` follows `public_fleet`)
   - `alignment` string
   - `primary_activity`, `secondary_activity` strings
   - `language` string (ISO 639-1)
   - `commitment` string
   - `roleplay` boolean nullable (`nil` = never synced)
   - `recruiting` boolean nullable
   - `rsi_synced_at` datetime
2. `Fleet`:
   - Constants with inclusion validations:
     - `ALIGNMENTS`: reuse `BlueprintSource::ALIGNMENTS`.
     - `ACTIVITIES`: RSI's 14 as slugs, mapped to RSI's activity names. RSI IDs: Transport 1, Smuggling 2, Scouting 3, Resources 4, Infiltration 5, Freelancing 6, Engineering 7, Security 8, Bounty Hunting 9, Piracy 10, Trading 11, Exploration 12, Social 13, Medical 14.
     - `COMMITMENTS`: casual/regular/hardcore.
     - `Rsi::Languages`: a frozen list of RSI's 184 ISO 639-1 codes with RSI's English names, used to map the search's "Lang: English" back to `en`.
   - `listed_in_directory?` = `rsi_verified? && public_fleet && listed != false`.
   - `scope :directory`:
     - `kept`, `public_fleet: true`
     - `rsi_verified_at` not nil, `rsi_verified_sid = rsi_sid`
     - `listed` nil or true
     - at least 2 kept accepted memberships, as a subquery rather than a join (see the model-filters-need-a-subquery trap)
   - Select `accepted_members_count` as a subquery column, so sorting and display need no N+1.
   - Don't filter on `rsi_verification_status`: a failed re-check keeps `rsi_verified_at`.
3. Ransack:
   - A `search` ransackable scope (name / fid / `rsi_verified_sid`, ILIKE) instead of `ransack_alias` in an `_or_` chain, which breaks.
   - Scopes for `members_count_gteq` / `lteq`, `alignment_in`, `activity_in` (matches primary OR secondary), `language_in`, `commitment_in`, `roleplay_eq`, `recruiting_eq`, `default_timezone_in`.
   - Extend `ALLOWED_SORTING_PARAMS` with member count asc/desc.
4. Reserve the FID `directory` so the new static route can't shadow a fleet.

### Phase 2: RSI sync
1. `Rsi::OrgPage`: also parse `ul.focus li.primary|secondary img[alt]` (activity names) and `li.commitment`.
2. New `Rsi::OrgSearch`:
   - `POST /api/orgs/getOrgs` with `search: <SID>`; parse `data.html`.
   - Pick the `org-cell` whose `.symbol` equals the SID exactly (the search is fuzzy).
   - Read `Lang`, `Commitment`, `Recruiting` and `Role play` from the `infoitem` label/value pairs.
   - Use the same `RsiRequestLog` block logging as `OrgPage`.
3. `FleetRsiSync` (lib) + `FleetRsiSyncJob`:
   - Skip unless the fleet is `rsi_verified?`.
   - Fetch both sources and write the RSI columns + `rsi_synced_at` via `update_columns` (no touch storm; still bust the fleet cache key if the jbuilder caches on `updated_at`).
   - A failed or blocked source leaves its columns as they were. An activity or language we don't know is logged and stored as nil.
4. `FleetRsiSyncAllJob` in `config/sidekiq_schedule.yml`, daily and production-only like the loaders:
   - Enqueues one `FleetRsiSyncJob` per verified fleet.
   - Spreads them over time (`perform_in` with an offset per index) so RSI doesn't see a burst.
5. Enqueue `FleetRsiSyncJob` from `FleetRsiVerification#apply` when the status becomes `:verified`.

### Phase 3: Settings API and page
1. `FleetPolicy#params_filter`:
   - `listed` is permitted only with `fleet:manage`.
   - `alignment` is permitted with `fleet:manage` / `fleet:update`.
   - The RSI-synced columns are never permitted.
2. Update the Fleet jbuilder `_base`, the `Fleet` schema (`additionalProperties: false`, so add the fields to `required`) and `FleetUpdateInput` (only `listed`, `alignment`). Add enum schemas for alignment / activity / commitment / language.
3. `pages/fleets/[slug]/settings/fleet.vue`, inside a section shown only once the fleet is verified:
   - The `listed` toggle, prefilled with `listed ?? publicFleet`. Its help text says a private fleet is never listed.
   - An alignment select.
   - A read-only block with the synced RSI values and "synced from RSI <time ago>". Language labels come from `Intl.DisplayNames` in the UI locale.

### Phase 4: Public directory API
1. Route: `namespace :public { resources :fleets, only: %i[index show] }`.
2. `Api::V1::Public::FleetsController#index`:
   - `authorize!` + `authorized_scope` on `Fleet.directory`
   - ransack `q` with a permitted list; `sorting_params(Fleet, …)` for `s`/`sorts`
   - Kaminari `per_page`, `pagination_header`
   - preload `logo_attachment: :blob`
   - gated by the feature flag (404 when off)
3. `Public::FleetPolicy#index?` and a relation scope.
4. A slim partial with these fields, instead of the full public `_fleet` partial (it carries features and the settings booleans):
   - name, slug, fid, verified SID, logo
   - member count
   - alignment, primary/secondary activity, language, commitment, roleplay, recruiting
   - timezone, createdAt
5. Schemas: `FleetDirectoryEntry`, `FleetDirectory` (`BaseList`), `FleetDirectoryQuery`, a sorting enum. Regenerate swagger + orval.

### Phase 5: Frontend directory page
1. Add the flag to the feature flag enum (see AGENTS.md and the feature-flag regen steps). It gates the route, the nav entry, and a `/fleets/` redirect to the directory (otherwise `fleet-add`).
2. Route order:
   - `fleets/directory/` before `:slug/` in `pages/fleets/routes.ts`
   - the matching route before `get "fleets/:slug"` in `config/routes/frontend_routes.rb`
3. The page uses `FilteredList` + `Paginator` + `ListToolbar` (sort) and `useFilters`, modelled on `pages/commodities/index.vue`. Components go under `components/Fleets/Directory/` (FilterForm, Row/card).
4. A nav entry in `FleetsNav` (+ its active list) and in the mobile nav.
5. Route meta titles in both `nav.*` and `title.*`, plus the Rails `title.yml` entry.

### Phase 6: Translations
1. Every new string goes into en, de, es, fr, it, zh-CN and zh-TW, by hand, in both the frontend JSON and the backend YAML. That covers the alignment, activity and commitment labels and the validation messages. Language names come from `Intl.DisplayNames`, not translation keys.

### Phase 7: Tests
1. Model tests for `Fleet.directory`:
   - Each exclusion separately: unverified, SID mismatch, private, `listed: false`, 1 member, discarded, a non-accepted member not counted.
   - `listed: nil` + public is included.
   - The new validations.
2. Parser tests for `Rsi::OrgPage` and `Rsi::OrgSearch` against saved HTML/JSON fixtures:
   - an exact symbol match among fuzzy results
   - an unknown language
   - a blocked response
3. `FleetRsiSync` tests:
   - writes the columns
   - skips unverified fleets
   - keeps the old values when a fetch fails
   - the verification success enqueues the sync
4. Policy tests: `listed` is manage-only, and the synced columns are not writable.
5. Integration tests:
   - `public_fleets_index_test.rb`: search, each filter, sort, pagination, the flag off, the response schema
   - extend `fleets_update_test.rb`
6. A Vitest for the settings section: hidden when unverified, the prefill.
7. An e2e spec: the directory lists a verified public fleet and finds it by SID.

## Intent Verification

- [ ] **Visibility:** a verified, public fleet with 2+ accepted members and `listed` not false appears. Unverifying it, making it private or dropping to 1 member removes it, with `listed` unchanged.
- [ ] **Settings toggle:** hidden for an unverified fleet. Prefilled on for a public verified fleet and off for a private one. Only `fleet:manage` can change it.
- [ ] **RSI sync:** after verifying, the fleet's activities, language, commitment, role play and recruiting match its RSI org. A change on RSI shows up after the next daily run. A failed fetch keeps the old values.
- [ ] **Directory contents:** name, FID, verified SID, logo, member count, alignment and the synced fields. Each entry links to the public Fleetyards fleet page.
- [ ] **Search/filter/sort:** search by name/FID/SID. Filter by member count, alignment, activity, language, commitment, role play, recruiting, timezone. Sort by member count and newest.
- [ ] **Feature flag:** with the flag off, the directory route, nav entry and API index are unavailable. With it on, `/fleets/` redirects to the directory.
- [ ] **Public API:** `GET /api/v1/public/fleets` is paginated and in the OpenAPI schema.
- [ ] **Locales:** no "translation missing" in any of the 7 locales.

## Key files

| File | Role |
|------|------|
| `app/models/fleet.rb` | `rsi_verified?` (:267), ransack config (:186-188), new scope + validations |
| `app/models/fleet_membership.rb` | accepted state, soft delete |
| `app/lib/rsi/org_page.rb` | org page fetch + parse, `RsiRequestLog` block logging |
| `app/lib/fleet_rsi_verification.rb` | `apply` on verified: enqueue the sync |
| `config/sidekiq_schedule.yml` | daily job entry |
| `app/policies/fleet_policy.rb` | `params_filter` (:60-86) |
| `app/policies/public/fleet_policy.rb` | public `show?`, new `index?` + scope |
| `app/controllers/api/v1/public/fleets_controller.rb` | new `index` |
| `app/controllers/api/v1/manufacturers_controller.rb` | ransack + pagination reference |
| `app/helpers/ransack_helper.rb` | `s` sort contract |
| `app/api_components/v1/schemas/fleets/fleet.rb` | Fleet schema |
| `app/api_components/v1/schemas/inputs/fleet_update_input.rb` | update input |
| `config/routes/api/fleets_routes.rb` | public namespace (:197-218) |
| `config/routes/frontend_routes.rb` | Rails frontend route order (:97-100) |
| `app/frontend/frontend/pages/fleets/routes.ts` | frontend route order |
| `app/frontend/frontend/pages/fleets/[slug]/settings/fleet.vue` | settings form |
| `app/frontend/frontend/pages/commodities/index.vue` | list page template |
| `app/frontend/frontend/components/Navigation/FleetsNav/index.vue` | nav entry |
| `test/factories/fleets.rb` | `:rsi_verified`, `members` transient |
| `test/integration/api/v1/public_fleets_show_test.rb` | integration test template |

## Not in scope (deferred)

- **Public "ask to join" from the fleet page.** It becomes its own issue before the PR merges. `FleetMembership` already has a `requested` state, and Discord join-request buttons exist (#5175), so the follow-up builds on those.
- **Linking to the RSI org page.** Decided against; see the issue body.
- **RSI archetype.** Decided against; see the issue body.

## Discovery Log

- **2026-10-02** Initial research and plan creation.
  - Fleets have no profile fields; only `default_timezone` exists.
  - There is no member counter cache.
  - Verification revoke and takeover use `update_columns`, so directory membership must be a query, never a callback-maintained flag.
  - RSI's listing filters on: activity (14 IDs), a single primary language (ISO 639-1, 184), commitment CA/RE/HA, role play, archetype (`generic`/`corp`/`pmc`/`faith`/`syndicate`/`club`), size, recruiting. Sorts are size, name, created, active.
  - The org page markup carries `li.model`, `li.commitment`, `ul.focus li.primary` / `li.secondary` (activity as icon `alt` text), and the member count. It has no language and no recruiting.
  - `POST /api/orgs/getOrgs` (JSON body with `search`, `page`, `pagesize` and the filter arrays) returns `data.html`, one `org-cell` per org. Each cell has `Archetype`, `Lang` (English name), `Commitment`, `Recruiting`, `Role play` and `Members` infoitems. The search is fuzzy: searching "TEST" returns 113,572 rows.
  - There is no recurring RSI re-check today; verification only runs on demand.

## Progress

- [ ] Phase 1: Data model
- [ ] Phase 2: RSI sync
- [ ] Phase 3: Settings API and page
- [ ] Phase 4: Public directory API
- [ ] Phase 5: Frontend directory page
- [ ] Phase 6: Translations
- [ ] Phase 7: Tests
