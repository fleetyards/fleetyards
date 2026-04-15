# Public Stats for Fleets and Hangar — Exec Plan

## Current State

- **Public fleet stats**: Fully implemented. `public_fleet_stats` boolean on Fleet model, `Public::FleetStatsController` with all chart endpoints + metrics, `PublicFleetStats` frontend component with stats panels and charts, toggle in fleet settings.
- **Public hangar stats**: Only basic counts (total, classifications, groups). No dedicated `public_hangar_stats` toggle, no metrics, no chart endpoints, no public stats page, no `PublicHangarStats` component.

## Goal

Bring public hangar stats to parity with public fleet stats: separate toggle, full metrics, chart endpoints, dedicated stats page.

## ~~Phase 1: Backend — Database + Model~~ ✅

- [x] Create migration: add `public_hangar_stats` boolean to `users` (default: `false`)
- [x] Update user update permitted params / API input schema to include `public_hangar_stats`
- [x] Add `public_hangar_stats` to User schema, UserPublic schema, and jbuilder views

### Files
- `db/migrate/20260415174001_add_public_hangar_stats_to_users.rb`
- `app/api_components/v1/schemas/inputs/user_update_Input.rb`
- `app/api_components/v1/schemas/user.rb`
- `app/api_components/v1/schemas/user_public.rb`
- `app/controllers/api/v1/users_controller.rb`
- `app/views/api/v1/users/_base.jbuilder`
- `app/views/api/v1/public/users/_base.jbuilder`
- `spec/factories/users.rb`

## ~~Phase 2: Backend — Policy + Authorization~~ ✅

- [x] Add `show_stats?` method to `Public::UserPolicy` — checks `record.public_hangar_stats?`
- [x] Update `Public::HangarStatsController` to use `authorize! @user, to: :show_stats?`

### Files
- `app/policies/public/user_policy.rb`
- `app/controllers/api/v1/public/hangar_stats_controller.rb`

## ~~Phase 3: Backend — Controller + Routes + Views~~ ✅

- [x] Rewrote `Public::HangarStatsController` with `ChartHelper`, metrics computation, and chart endpoints
- [x] Added chart routes to public hangar_stats resource
- [x] Added metrics block to `public/hangar_stats/show.jbuilder`
- [x] Updated `HangarStatsPublic` schema to include metrics

### Files
- `app/controllers/api/v1/public/hangar_stats_controller.rb`
- `config/routes/api/hangar_routes.rb`
- `app/views/api/v1/public/hangar_stats/show.jbuilder`
- `app/api_components/v1/schemas/hangar/hangar_stats_public.rb`

## ~~Phase 4: Backend — Tests~~ ✅

- [x] Updated existing show spec with `public_hangar_stats` flag
- [x] Added request specs for all 4 chart endpoints
- [x] Tests verify 404 when `public_hangar_stats` is false

### Files
- `spec/requests/api/v1/public/hangars/stats/show_spec.rb`
- `spec/requests/api/v1/public/hangars/stats/models_by_size_spec.rb`
- `spec/requests/api/v1/public/hangars/stats/models_by_production_status_spec.rb`
- `spec/requests/api/v1/public/hangars/stats/models_by_manufacturer_spec.rb`
- `spec/requests/api/v1/public/hangars/stats/models_by_classification_spec.rb`

## ~~Phase 5: Backend — Lint + Schema~~ ✅

- [x] Ran `bundle exec standardrb --fix` on all changed Ruby files
- [x] Ran `./bin/generate-schema` to update OpenAPI spec and regenerate Orval clients

## ~~Phase 6: Frontend — Settings~~ ✅

- [x] Added `publicHangarStats` toggle to hangar settings page
- [x] Added translations (en, de, es, fr)

### Files
- `app/frontend/frontend/pages/settings/hangar.vue`
- `app/frontend/translations/{en,de,es,fr}/labels.json`

## ~~Phase 7: Frontend — Regenerate API Client~~ ✅

- [x] Orval regenerated with new public hangar stats chart hooks
- [x] Generated: `usePublicHangarModelsByClassification`, `usePublicHangarModelsBySize`, `usePublicHangarModelsByProductionStatus`, `usePublicHangarModelsByManufacturer`

## ~~Phase 8: Frontend — PublicHangarStats Component~~ ✅

- [x] Created `PublicHangarStats` component following `PublicFleetStats` pattern
- [x] Stats panels: total ships, unique models, flight ready, cargo, money, credits, ingame value, avg pledge price, manufacturers, largest/smallest ship, min/max crew
- [x] Charts: by classification, size, manufacturer, production status

### Files
- `app/frontend/frontend/components/Hangar/PublicHangarStats/index.vue`

## ~~Phase 9: Frontend — Route + Page~~ ✅

- [x] Added `/hangar/:username/stats` route in `config/routes/frontend_routes.rb`
- [x] Added `hangar-public-stats` route in `[username]/routes.ts`
- [x] Created stats page with `PublicHangarStats` component
- [x] Page redirects to hangar if `publicHangarStats` is disabled
- [x] Added headline translations in all languages

### Files
- `config/routes/frontend_routes.rb`
- `app/frontend/frontend/pages/hangar/[username]/stats.vue`
- `app/frontend/frontend/pages/hangar/[username]/routes.ts`
- `app/frontend/translations/{en,de,es,fr,zh-CN,zh-TW,it}/headlines.json`

## ~~Phase 10: Frontend — Lint~~ ✅

- [x] Ran `pnpm lint:fix` — all clean
- [x] TypeScript errors are pre-existing auto-import issues (same as existing pages)

## Verification

1. [x] `rails db:migrate` — success
2. [x] `rspec spec/requests/api/v1/public/hangars/stats/` — 12 examples, 0 failures
3. [x] `rspec spec/requests/api/v1/public/hangars/` — 21 examples, 0 failures
4. [ ] `rspec` (full suite)
5. [ ] `pnpm test`
6. [ ] Manual: enable `publicHangarStats` on user, visit `/hangar/:username/stats` logged out — see full stats + charts
7. [ ] Manual: disable toggle — get 404
8. [ ] Manual: compare metrics with private hangar stats for same user
