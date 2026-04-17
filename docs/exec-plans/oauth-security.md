# OAuth Security: Re-auth + Deferred Password Setup

## Goal

OAuth-only users can access secure settings pages by re-authenticating via their OAuth provider (primary) or by setting a password (fallback).

## Context

OAuth users (Discord, Twitch, Google, GitHub, Bluesky) get a random 60-char password via `Devise.friendly_token` they never see. The `SecurePage` component blocks access to Account and Security settings by requiring password re-entry — completely locking out OAuth-only users.

## Decisions

### D1 — Dual approach: OAuth re-auth + password fallback

OAuth re-auth is the primary path (no passwords needed, same security as password re-entry). Password setup is offered as a fallback for resilience (provider outages, user preference). Rejected: skip confirmation entirely (security risk with stolen sessions), force password at registration (defeats OAuth simplicity).

### D2 — Track manual password status via database column

Add `password_set_manually` boolean to users. Needed to distinguish OAuth-only users from regular users. The `encrypted_password` column is always populated (even for OAuth users), so we can't infer this from existing data.

### D3 — Re-use existing confirm-access token/cookie mechanism

The OAuth re-auth callback issues the same `access_confirmation_verifier` token or `ACCESS_CONFIRMED` cookie that the password-based `confirm_access` endpoint already uses. No new confirmation mechanism needed.

## Phase 1 — Database: track manual password status

1. Add migration `add_password_set_manually_to_users`
   - `password_set_manually` boolean, default `false`, not null
   - Backfill: `UPDATE users SET password_set_manually = true WHERE id NOT IN (SELECT DISTINCT user_id FROM omniauth_connections)`

## Phase 2 — Backend: User model

1. Add `oauth_only?` method — `!password_set_manually && omniauth_connections.any?`
2. Add callback or override to set `password_set_manually = true` when password is explicitly changed (via `reset_password` or `update_with_password`)

## Phase 3 — Backend: OAuth re-auth for access confirmation

1. Extract token/cookie generation from `SessionsController#confirm_access` into a shared concern (`AccessConfirmable`) on `Api::BaseController`
2. In `OmniauthCallbacksController`, when user is already signed in and `omniauth.origin` contains a confirm-access marker:
   - Verify the returning OAuth UID matches one of the current user's `omniauth_connections`
   - Call the shared concern to issue confirm-access token/cookie
   - Redirect to frontend settings URL with `?access_confirmed=true`
3. Add `frontend_confirm_access_origin_url` route helper for the origin marker

## Phase 4 — Backend: Set initial password endpoint

1. Add `set_initial` action to `Api::V1::PasswordsController`
   - Guard: `current_user.oauth_only?` — return 403 if not
   - Accepts `password` + `password_confirmation` (no `current_password`)
   - Sets password and `password_set_manually = true`
   - Also issues confirm-access token/cookie (so user gets immediate access after setting password)
2. Add route: `POST /api/v1/passwords/set_initial`

## Phase 5 — Backend: Expose fields to frontend

1. Add `password_set_manually` and `oauth_only` to `app/views/api/v1/users/_base.jbuilder`
2. Add fields to OpenAPI schema in `app/api_components/v1/schemas/user.rb`

## Phase 6 — Backend: Adapt change password for OAuth-only users

1. In `PasswordsController#update`, if `current_user.oauth_only?`, use `user.reset_password(password, password_confirmation)` instead of `update_with_password`

## Phase 7 — Frontend: Update User type

1. Add `passwordSetManually: boolean` and `oauthOnly: boolean` to `User` interface in `app/frontend/services/fyApi/models/User.ts`

## Phase 8 — Frontend: SecurePage component

1. Modify `SecurePage` to detect OAuth-only user via `currentUser.oauthOnly`
2. Three states:
   - **Regular user:** Current password prompt (unchanged)
   - **OAuth-only user:** "Confirm via [Provider]" button(s) for each `authConnections` entry + "Or set a password instead" link
   - **Set password form:** New password + confirm fields, calls `set_initial` endpoint
3. OAuth button triggers POST to `/users/auth/{provider}` with origin set to confirm-access marker (reuse `OauthBtn` form POST pattern)
4. Handle `?access_confirmed=true` query param on return: call `sessionStore.confirmAccess()`, strip param from URL

## Phase 9 — Frontend: ChangePasswordForm

1. If `currentUser.oauthOnly`, hide `currentPassword` field, change button text to "Set Password"
2. Adjust validation schema conditionally

## Intent Verification

- [ ] **OAuth-only user can access Account settings** — sign up via Discord, navigate to Account settings, see "Confirm via Discord" button, click, re-auth, access granted
- [ ] **Password fallback works** — on SecurePage, click "Set a password", set password, access confirmed immediately
- [ ] **Regular user unchanged** — existing password prompt works as before
- [ ] **Multi-provider user** — sees buttons for all connected providers
- [ ] **Change password adapts** — OAuth-only user sees simplified form; after setting password, sees full form
- [ ] **Post-password-set behavior** — once password is set, future visits show normal password prompt

## Key files

| File | Role |
|------|------|
| `app/controllers/omniauth_callbacks_controller.rb` | OAuth callback handling — add confirm-access flow |
| `app/controllers/api/v1/sessions_controller.rb` | Current confirm_access — extract shared concern |
| `app/controllers/api/v1/passwords_controller.rb` | Password change — add set_initial, adapt update |
| `app/controllers/api/base_controller.rb` | access_confirmed? helper — add shared concern |
| `app/models/user.rb` | Add oauth_only?, password tracking |
| `app/views/api/v1/users/_base.jbuilder` | Expose new fields |
| `app/api_components/v1/schemas/user.rb` | OpenAPI schema |
| `app/frontend/frontend/components/core/SecurePage/index.vue` | Main UI changes |
| `app/frontend/frontend/components/Security/ChangePasswordForm/index.vue` | Adapt for OAuth users |
| `app/frontend/services/fyApi/models/User.ts` | User type |
| `app/frontend/frontend/stores/session.ts` | Access confirmation state |

## Not in scope (deferred)

- **Revoking OAuth connections** — removing a provider while still OAuth-only would need password enforcement first
- **2FA via OAuth** — using provider as a second factor

## Discovery Log

- **2026-04-17** Initial research and plan creation
- **2026-04-17** Implementation of all phases

## Progress

- [x] Phase 1 — Database migration
- [x] Phase 2 — User model
- [x] Phase 3 — OAuth re-auth backend
- [x] Phase 4 — Set initial password endpoint
- [x] Phase 5 — Expose fields
- [x] Phase 6 — Adapt change password
- [x] Phase 7 — Frontend User type
- [x] Phase 8 — SecurePage component
- [x] Phase 9 — ChangePasswordForm
