# Raffle system for Star Citizen gift codes

Working plan for #6024. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Admins run raffles for CIG gift codes; confirmed users opt in by accepting the participation conditions and are listed publicly, an admin draws a random order of entrants; the first claims the raffle's single code before a deadline, otherwise the next in line takes over.

## Open questions
- **Conditions wording** — who reviews the legal copy before the first real raffle? The plan ships a draft in all 7 locales.

## Data model

- `raffles` (uuid): `title`, `description`, `model_id` (prize, nullable for non-ship prizes), `code` (`encrypts :code`, non-deterministic), `starts_at`, `ends_at`, `claim_period_days` (default 14, decided), `published_at`, `drawn_at`, `drawn_by_id` (AdminUser), timestamps, `has_paper_trail ignore: [:code]`. Current winner = entry with `won_at` set and neither `claimed_at` nor `forfeited_at`, or the claimed one.
- `raffle_entries` (uuid): `raffle_id`, `user_id` (nullable, nullified on account deletion after the draw), `username` (snapshot taken on user destroy), `email` (`encrypts`, snapshot at entry, cleared when the raffle concludes), `verification_code_digest`, `verification_sent_at`, `conditions_accepted_at`, `conditions_version`, `draw_position` (set by the draw, unique per raffle), `won_at`, `claim_deadline_at`, `claimed_at`, `claimed_by_admin_id` (manual hand-over), `forfeited_at`, timestamps; unique index on `[raffle_id, user_id]`.
- Raffle state is derived: draft (unpublished), upcoming, open (`starts_at..ends_at`), closed (past `ends_at`, not drawn), drawn.

## What changed

### Phase 1 — Backend core
1. Feature flag `raffles` in `config/feature_flags.yml`; `RafflesFeatureConcern` modelled on `ShoppingCartFeatureConcern`.
2. Migrations and models `Raffle`, `RaffleEntry` with validations (entry only while open, `ends_at > starts_at`, code required before publishing, code immutable once drawn).
3. `Raffles::Draw` service: inside a transaction with a row lock on the raffle, refuses if not closed, already drawn or without confirmed entrants, shuffles all confirmed entries with `SecureRandom` into `draw_position`, promotes position 1 (`won_at`, `claim_deadline_at`), sets `drawn_at`/`drawn_by`, then notifies after commit.
4. `Raffles::Promote` service + `Raffles::ForfeitExpiredJob` (scheduled, hourly): forfeit wins past `claim_deadline_at`, promote the next position whose user still exists and is confirmed (skipping others as forfeited), notify; mark the raffle exhausted when nobody is left. Clear all email snapshots and verification digests once the raffle is claimed or exhausted.
5. `User` `before_destroy`: snapshot `username` onto entries of drawn raffles and nullify `user_id`; delete entries of undrawn raffles.
6. `Raffle::CONTACTS` (Discord handle `torlekmaru`, invite `https://discord.gg/6EQKAsb`) used by the conditions, the raffle page and the win mail via interpolation, so the 7 locales carry no addresses.
6b. `Raffle::CONDITIONS_VERSION` constant; an entry without `conditions_accepted: true` in the input is a 400.
7. Notification type `raffle_won` (with the claim deadline) in `Notification::TYPES` (in-app + mail channels); the mail links to the reveal page and never contains the code.

### Phase 2 — Admin API + admin app
1. `Admin::Api::V1::RafflesController` CRUD (GameEvent pattern), `POST /raffles/:id/draw`, `POST /raffles/:id/entries/:entry_id/send-verification` (mails a 6-digit code to the snapshot email, rate-limited, stores only a digest) and `POST /raffles/:id/entries/:entry_id/claim` (requires the matching code; manual hand-over for a deleted-account winner), entries list with draw positions and claim state; the code is write-only in the input and returned masked (`code_set: true`).
2. `Admin::RafflePolicy` with `resource_access [:raffles]`, key added to `AdminUser::RESOURCE_ACCESS`, data migration granting it to existing full-access roles.
3. Components: `raffle`, `raffles`, inputs, query/sort.
4. Admin pages `app/frontend/admin/pages/raffles/` (index, create, `[id]`, `[id]/edit`), code field, draw button with confirm, nav entry under community.

### Phase 3 — Public API + frontend
1. `Api::V1::RafflesController` index/show (public, published only, entry count, current winner, claim deadline and forfeited winners once drawn,
   `GET /raffles/:id/entries` public paginated list of entrant usernames, `entered` + `won` flags for the current user).
2. `Api::V1::RaffleEntriesController` create/destroy (authenticated, `RaffleEntryPolicy#create?` requires `user.confirmed?` and an open raffle; `RecordNotUnique` → 400).
3. `POST /raffles/:id/claim` for the current winner only, before the deadline: sets `claimed_at` and returns the code; later `GET /raffles/:id/code` re-shows it.
4. Frontend pages `raffles/index.vue`, `raffles/[id].vue` (participation conditions block, enter dialog with a required acceptance checkbox, withdraw, entrant list, winner, reveal panel), route `meta.feature: FeatureFlagName.RAFFLES`, nav item gated on the flag, notification action in `useNotificationActions.ts`.

### Phase 4 — Locales, docs, e2e
1. All 7 locales: `raffles.json` (incl. participation conditions copy), nav/title/headlines, labels (privilege + notification type), `activerecord.yml`, `validation_error.yml`, `messages.yml`, `notifications.yml`, `mailer.yml`.
2. Playwright scenario + spec: enter, admin draws, winner reveals.

## Intent Verification

- [ ] **Admin creates and publishes a raffle with its code** — the code never appears unmasked in admin JSON or versions
- [ ] **Confirmed user enters once, can withdraw before the deadline** — second entry, late entry and entry without accepted conditions are 400, unconfirmed user is 403; acceptance time and version are stored
- [ ] **Transparency** — the raffle page shows the conditions and every entrant's username; a withdrawn entrant disappears from the list
- [ ] **Draw** — exactly one winner from the confirmed entrants, drawn twice or with no entrants is refused, `drawn_by`/`drawn_at` recorded
- [ ] **Winner** — gets notification + email with the deadline (no code in email), claims and reveals the code; any other user gets 403/404
- [ ] **Deadline** — an unclaimed win is forfeited after the deadline and the next confirmed entrant in draw order is notified with a fresh deadline
- [ ] **Deleted account** — a winner's entry survives account deletion with the username; an admin can mark it claimed before the deadline only with the code mailed to the entry's email snapshot
- [ ] **Email snapshot** — never in plain text in admin JSON (masked), gone once the raffle concludes
- [ ] **Public page** — lists raffles, entry counts, the winner's username after the draw
- [ ] **Flag off** — public API 403s, routes and nav hidden

## Key files

| File | Role |
|------|------|
| `app/models/game_event.rb`, `app/controllers/admin/api/v1/game_events_controller.rb` | Admin CRUD template |
| `app/controllers/api/v1/tour_join_requests_controller.rb` | Opt-in/withdraw template |
| `app/controllers/concerns/shopping_cart_feature_concern.rb` | Feature-flag gate template |
| `app/models/notification.rb`, `app/mailers/notification_mailer.rb` | Win notification + mail |
| `app/models/admin_user.rb` | `RESOURCE_ACCESS` for the `raffles` privilege |
| `app/models/push_subscription.rb` | Existing `encrypts` usage |
| `config/feature_flags.yml` | Flag registry |

## Not in scope (deferred)
- **Reminder email before the deadline** — nice to have, not required.
- **Extra eligibility rules** (account age, verified RSI handle) — only if multi-accounting shows up.
- **Code format validation** — CIG's format is unknown.

## Discovery Log

- **2026-10-27** Initial research and plan creation. Production already blocks sign-in for unconfirmed accounts (`allow_unconfirmed_access_for` is only set in CI/dev), so the `confirmed?` gate is a backstop; it is the first explicit one in the codebase.
- **2026-10-27** Implemented. The draw lives in `Raffles::Draw`, the forfeit-and-promote step in `Raffles::Succession`, run hourly by `Raffles::SuccessionJob`. The admin draw and verification hand-over sit on `/raffles/:id/entries` in the admin app.
- **2026-10-27** Frontend strings for both apps live in one `translations/<locale>/raffles.json` per locale, deep-merged into the catalogue; `labels.json` was not touched (a JSON round-trip of it drops duplicate keys).
- **2026-10-27** The unconfirmed-account 403 is tested on the policy, not the endpoint: Devise only allows unconfirmed sign-in when `CI` is set, so the endpoint test answered 401 locally and 403 on CI.
- **2026-10-27** Claim deadline with next-in-line promotion; draw order fixed at draw time; deleted accounts keep their username on drawn entries (`preserve_payout_participant_names` precedent).
- **2026-10-27** Entrants are public (CIG transparency requirement), entry requires accepting the participation conditions.
- **2026-10-27** One code per raffle: dropped `raffle_codes`; code and winner live on `raffles`.

## Progress
- [x] Phase 1 — Backend core
- [x] Phase 2 — Admin API + admin app
- [x] Phase 3 — Public API + frontend
- [x] Phase 4 — Locales, docs, e2e
