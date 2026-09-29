# Verify an RSI handle with a token in the RSI profile bio

Working plan for #5293. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A user can verify their RSI handle by putting a token in their RSI bio, as an alternative to Citizen iD. A verified handle is held by one account at a time.

## Open questions
- None.

## What changed

### Phase 1 — Schema and model
1. Migration: add `rsi_verification_token`, `rsi_verification_status`, `rsi_verification_checked_at`, `rsi_handle_verified_at` and `rsi_handle_verified_via` to `users`. Backfill `via = citizenid` for rows that are already verified. Resolve the existing duplicates, keeping the latest Citizen iD connection. Add a partial unique index on `lower(rsi_handle) WHERE rsi_handle_verified`.
2. Data migration: backfill a token for every user.
3. `User`:
   - token on create
   - `verify_rsi_handle` / `clear_rsi_handle_verification`
   - a `before_save` that takes the handle from other accounts, and an `after_commit` that notifies them
   - a status that resets when the handle changes
   - a cooldown
4. The Citizen iD callback and the disconnect use the new helpers. A disconnect clears only a Citizen iD verification.

### Phase 2 — Check
1. `Rsi::CitizenPage`: fetch `/en/citizens/<handle>`; parse the handle name and the bio.
2. `UserRsiVerification` plus `UserRsiVerificationJob`, with the same generation, lock and retry logic as the fleet check.
3. Notification type `rsi_handle_verification_lost`, in 7 locales, with a cable enum entry and examples.

### Phase 3 — API
1. `GET/POST/DELETE /me/rsi-verification`, plus `POST /me/rsi-verification/check`, with integration tests and a schema.
2. `rsiHandleVerifiedVia` on the user, public-user and admin-user payloads.
3. Admin: revoke a user's handle verification.

### Phase 4 — Frontend
1. Profile settings: a Verify button next to the handle opens a three-step modal; a verified handle can have its verification removed.
2. Verified-badge tooltips name the method.
3. Admin user page: show the method and revoke.
4. Translations in all 7 locales.

## Key files

| File | Role |
|------|------|
| `app/lib/fleet_rsi_verification.rb` | Pattern the user check mirrors |
| `app/controllers/omniauth_callbacks_controller.rb` | Citizen iD path |
| `app/frontend/frontend/components/Fleets/RsiVerificationModal/index.vue` | Pattern for the modal |
| `app/frontend/frontend/pages/settings/profile.vue` | Where the flow starts |

## Not in scope (deferred)
- **Membership verification from the citizen's organisations page** — this stays with Citizen iD's claim.

## Discovery Log

- **2026-09-29** In the dev dump, 14 handles are verified on more than one account and 60 handles are shared by several accounts, verified or not. The token must be read from `.entry.bio .value`: the page also shows the main org's name, which that org's officers control.
- **2026-09-29** `db/schema.rb` and the model annotations were written by hand because the migration was not run against a dev database. The dedup query was dry-run read-only against the dump: it unverifies exactly the 14 duplicates and keeps 1255 handles. No verified row lacks a handle.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [ ] Live UI check of the profile modal on a dev server
