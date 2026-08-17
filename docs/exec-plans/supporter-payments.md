# Supporter Payments — Exec Plan

A dedicated public page showing supporter contributions and progress toward a monthly funding goal, with admin UI to manage both the goal (with history) and contributions (free-text name, recurring or one-time, opt-out anonymous flag).

## Decisions (from clarifying questions)

- **Supporter identity**: free-text name (no User association). Add per-contribution `anonymous` flag so name can be hidden publicly.
- **Funding goal**: history kept via `effective_from` dated rows; admin updates a new row when the goal changes, no monthly bookkeeping required. The active goal is the latest row with `effective_from <= today`.
- **Public display**: shows names + amounts, except for entries flagged anonymous (still count toward total).
- **Recurrence**: one-time and recurring (monthly) supported. Recurring rows are counted for every month between `started_at` and `ended_at` (null = ongoing).
- **Currency**: single currency (EUR) — store cents as `integer`, currency column kept for future flexibility but UI is EUR-only for now.

## Data model

### Migration 1 — `funding_goals`
- `id` uuid pk
- `amount_cents` integer, not null
- `currency` string, default "EUR", not null
- `effective_from` date, not null
- `created_at`, `updated_at`
- index: `effective_from desc`

### Migration 2 — `supporter_contributions`
- `id` uuid pk
- `name` string, not null
- `amount_cents` integer, not null
- `currency` string, default "EUR", not null
- `anonymous` boolean, default false, not null
- `recurring` boolean, default false, not null
- `started_at` date, not null  ← first (or only) contribution date
- `ended_at` date, nullable    ← only meaningful when `recurring`
- `note` text, nullable        ← admin-internal note
- `created_at`, `updated_at`
- index: `started_at desc`, `(recurring, ended_at)`

### Models

`app/models/funding_goal.rb`
- validates `amount_cents > 0`, `effective_from` present
- scope `:current` → `where("effective_from <= ?", Date.current).order(effective_from: :desc).limit(1)`
- class method `.for_month(date)` → latest row with `effective_from <= end_of_month(date)`

`app/models/supporter_contribution.rb`
- validates name, amount_cents > 0, started_at; `ended_at >= started_at` if present
- scope `:active_in(month_start, month_end)`
  - one-time: `recurring = false AND started_at BETWEEN month_start AND month_end`
  - recurring: `recurring = true AND started_at <= month_end AND (ended_at IS NULL OR ended_at >= month_start)`
- class method `.monthly_total(date = Date.current)` → sum of `amount_cents` for `active_in(month_start, month_end)`

## Backend API

### Admin routes (`config/routes/admin/api/v1_routes.rb`)
```ruby
resources :funding_goals, path: "funding-goals", only: %i[index show create update destroy]
resources :supporter_contributions, path: "supporter-contributions", only: %i[index show create update destroy]
```

### Admin controllers (Ransack/pagination pattern matching `ManufacturersController`)
- `app/controllers/admin/api/v1/funding_goals_controller.rb` — full CRUD
- `app/controllers/admin/api/v1/supporter_contributions_controller.rb` — full CRUD

### Admin policies + resource access
Add a new resource access slug `:supporters` (shared by both policies — same admin domain). Admins must have `"supporters"` in their `resource_access` array to manage either goals or contributions.
- `app/policies/admin/funding_goal_policy.rb` → `resource_access = [:supporters]`
- `app/policies/admin/supporter_contribution_policy.rb` → `resource_access = [:supporters]`

Wherever admin resource lists exist (admin user edit form, dashboard, etc. — locate by grepping for `"manufacturers"` as a string), add `"supporters"` to the available options.

### Public route (`config/routes/api/v1_routes.rb`)
```ruby
get "supporters/progress" => "supporters#progress"
```

### Public controller
- `app/controllers/api/v1/supporters_controller.rb` with `progress` action
- Returns: current month's goal (amount/currency), current month total, list of contributions active this month (with name OR `Anonymous` placeholder based on `anonymous` flag; amount always included; `recurring` flag included).

## OpenAPI schemas (`app/api_components/`)

Never edit `swagger/*.yaml` directly — defined per `feedback_never_edit_schema_yaml`.

### Admin schemas (`app/api_components/admin/v1/schemas/`)
- `funding_goal.rb` — id, amountCents, currency, effectiveFrom, createdAt, updatedAt
- `funding_goal_params.rb` — amountCents, currency (optional), effectiveFrom
- `supporter_contribution.rb` — id, name, amountCents, currency, anonymous, recurring, startedAt, endedAt, note, createdAt, updatedAt
- `supporter_contribution_params.rb` — same minus id/timestamps; ended_at/note optional

### Public schema (`app/api_components/v1/schemas/`)
- `support_progress.rb` — `goal: { amountCents, currency, effectiveFrom } | null`, `monthlyTotal: { amountCents, currency }`, `contributions: [{ displayName, amountCents, currency, recurring }]`
- Per `feedback_response_never_nullable`: omit absent fields (e.g. `goal` only included if a goal row exists), exclude from `required`.

### Regenerate schemas + Orval clients
- `./bin/generate-schema` then standardrb + linter per `feedback_generate_schema`.
- `pnpm orval` to regenerate Vue Query hooks under `app/frontend/services/fyAdminApi/` and the public API client.

## Admin UI (`app/frontend/admin/pages/`)

Follow the manufacturers pattern: `index.vue` (list, sortable, paginated), `create.vue`, `[id].vue` (edit/delete), with `routes.ts` and nested `[id]/routes.ts`.

### Funding goals
- `funding-goals/index.vue` — table: effective_from, amount, currency; sort by effective_from desc; row click → edit
- `funding-goals/create.vue` — form: amount (EUR input), effective_from (date picker)
- `funding-goals/[id].vue` — same form + delete

### Supporter contributions
- `supporter-contributions/index.vue` — table: name, amount, started_at, ended_at, recurring, anonymous; ransack filters (name_cont, recurring_eq, anonymous_eq)
- `supporter-contributions/create.vue` — form: name, amount, started_at, ended_at (only when recurring=true), recurring switch, anonymous switch, note
- `supporter-contributions/[id].vue` — edit/delete

### Register pages in admin routes
- `app/frontend/admin/pages/routes.ts` — add entries with `access: ["supporters"]` and `needsAuthentication: true` matching the existing pattern
- Add nav entries in the admin sidebar component (locate sidebar/menu component and add `funding-goals` + `supporter-contributions` under a "Supporters" group, gated on `sessionStore.hasAccessTo("supporters")`)

## Public page (`app/frontend/frontend/pages/`)

- New page `support.vue` (route `/support`) showing:
  - Goal progress bar (current month total vs. active goal)
  - Live total and goal in EUR
  - Contributor list — name + amount, anonymous entries shown as `Anonymous`, recurring entries marked with a recurring badge
  - "How to contribute" section that re-uses links from existing `SupportBtn/Modal/index.vue`

## Support button modal widget

Extract a small shared `SupportProgress` component (`app/frontend/frontend/components/SupportProgress/index.vue`) that fetches `GET /api/v1/supporters/progress` and renders a compact progress bar with current total / monthly goal. Use it in two places:
- Inside `SupportBtn/Modal/index.vue` at the top, above the existing PayPal/Patreon/etc. links — gives a live preview without leaving the modal.
- On the new `/support` page (larger variant with the full contributor list below).
The modal widget links through to `/support` for the detailed view.

## i18n

Add German + English translations for:
- Page titles ("Supporter Funding", "Funding Goals", "Supporter Contributions")
- Form labels, table headers, validation messages
- Public page strings ("Goal", "This Month", "Anonymous", "Recurring", "One-time")

## Testing

Minitest (per project conventions):
- `test/models/funding_goal_test.rb` — `.current`, `.for_month` boundary cases
- `test/models/supporter_contribution_test.rb` — `.active_in` with one-time/recurring/edge dates, `.monthly_total`
- `test/controllers/admin/api/v1/funding_goals_controller_test.rb` — CRUD + policy
- `test/controllers/admin/api/v1/supporter_contributions_controller_test.rb` — CRUD + policy
- `test/controllers/api/v1/supporters_controller_test.rb` — progress endpoint with/without active goal, anonymous masking, recurring counted across months

## Resolved decisions

1. Currency stays EUR-only for now (schema keeps `currency` column for future flexibility).
2. Anonymous contributions: name hidden, amount still visible publicly.
3. New `/support` page **plus** an embedded progress widget inside the existing `SupportBtn` modal (shared component).
4. New `:supporters` resource_access slug — both policies require it; admins must be granted explicitly.

## Commit slicing (one logical change per commit, per user prefs)

1. `feat(db): add funding_goals and supporter_contributions tables`
2. `feat(models): add FundingGoal and SupporterContribution models with scopes`
3. `feat(api): add admin CRUD for funding goals`
4. `feat(api): add admin CRUD for supporter contributions`
5. `feat(api): add public supporters progress endpoint`
6. `feat(admin-ui): funding goals CRUD pages`
7. `feat(admin-ui): supporter contributions CRUD pages`
8. `feat(frontend): shared SupportProgress widget`
9. `feat(frontend): public /support page with goal progress and contributor list`
10. `feat(frontend): embed SupportProgress widget in SupportBtn modal`
11. `chore(i18n): add supporter funding translations`
