# OAuth Security: Email Code Confirmation + Password Simplification

## Goal

OAuth-only users can access secure settings pages by confirming their identity via a 6-digit email code. The change password form no longer requires the current password since the confirm-access gate already proves identity. OAuth connections can be disconnected from the security page.

## Context

OAuth users (Discord, Twitch, Google, GitHub, Bluesky) get a random 60-char password via `Devise.friendly_token` they never see. The `SecurePage` component blocks access to Account and Security settings by requiring password re-entry — completely locking out OAuth-only users.

## Decisions

### D1 — Email code confirmation for OAuth-only users

Sends a 6-digit code via email. The user enters it on the same page — no new tabs, no provider dependency, simple UX. Rejected: OAuth re-auth (complex, provider-dependent), skip confirmation entirely (security risk), force password at registration (defeats OAuth simplicity).

### D2 — Track manual password status via database column

Add `password_set_manually` boolean to users. Needed to distinguish OAuth-only users from regular users. The `encrypted_password` column is always populated (even for OAuth users). Backfill uses a timestamp heuristic: if first OAuth connection was created within 1 minute of account creation, user signed up via OAuth.

### D3 — Remove current_password from change password flow

The confirm-access gate already proves identity, making current password re-entry redundant. Simplifies the flow for all users.

### D4 — OAuth connections can be disconnected

Users can disconnect OAuth providers from the security settings page. Guard prevents removing the last connection for OAuth-only users (no password set).

## What changed

### Phase 1 — Database: track manual password status

- Migration `add_password_set_manually_to_users` with timestamp-based backfill
- `User#oauth_only?` method
- `User#reset_password` and `User#update_with_password` overrides to set `password_set_manually = true`

### Phase 2 — Backend: email code confirmation

- `SessionsController#send_confirm_access_email` generates 6-digit code, signs it with `MessageVerifier`, emails via `ConfirmAccessMailer`
- `SessionsController#verify_confirm_access_code` validates code against signed token, issues access confirmation cookie
- `AccessConfirmable` concern extracted for shared token/cookie generation
- `ConfirmAccessMailer` with code template

### Phase 3 — Backend: simplify password change

- `PasswordsController#update` uses `reset_password` instead of `update_with_password` (no current password needed)
- Removed `currentPassword` from `PasswordInput` schema
- Removed `set_initial` endpoint (no longer needed)

### Phase 4 — Backend: disconnect OAuth connections

- `OmniauthConnectionsController#destroy` with ownership policy
- Guard: cannot remove last connection for OAuth-only users
- Returns updated user object

### Phase 5 — Backend: expose fields and sanitize usernames

- `password_set_manually` and `oauth_only` in user serializer and OpenAPI schema
- OAuth username sanitized with `transliterate` + regex (preserves casing)
- Username included in `failure_username_taken` error message

### Phase 6 — Frontend: SecurePage

- OAuth-only users: "Send confirmation email" button → enter 6-digit code
- Regular users: password prompt (unchanged)

### Phase 7 — Frontend: ChangePasswordForm

- Removed `currentPassword` field for all users
- Removed "Forgot password?" link (not needed behind confirm-access)

### Phase 8 — Frontend: OAuth disconnect

- `OauthBtn` gains `disconnectable` mode with danger variant and disconnect emit
- `SocialLogins` handles disconnect mutation, sorts connected providers first
- Enabled on security settings page

### Phase 9 — Frontend: misc improvements

- `OauthBtn` passes stored redirect-back URL as OAuth origin for proper post-login redirect
- Flash alert/warning notifications use 10s timeout instead of 3s
- All translations added to 7 languages

## Intent Verification

- [x] **OAuth-only user can confirm access** — send email, enter 6-digit code, access granted
- [x] **Regular user unchanged** — existing password prompt works
- [x] **Change password simplified** — no current password required for any user
- [x] **OAuth disconnect works** — connected providers show disconnect button on security page
- [x] **Last connection guard** — OAuth-only users cannot remove their last provider
- [x] **Password reset flow** — sets `password_set_manually`, user gets password prompt going forward
- [x] **Username sanitization** — OAuth names with spaces/unicode handled correctly
- [x] **Post-login redirect** — OAuth login redirects back to intended page

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/sessions_controller.rb` | Confirm access: password, email code send/verify |
| `app/controllers/api/v1/passwords_controller.rb` | Simplified password change (no current_password) |
| `app/controllers/api/v1/omniauth_connections_controller.rb` | Disconnect OAuth providers |
| `app/controllers/omniauth_callbacks_controller.rb` | Username sanitization, error messages |
| `app/controllers/concerns/access_confirmable.rb` | Shared token/cookie generation |
| `app/mailers/confirm_access_mailer.rb` | 6-digit code email |
| `app/models/user.rb` | `oauth_only?`, password tracking |
| `app/policies/omniauth_connection_policy.rb` | Authorization for disconnect |
| `app/frontend/frontend/components/core/SecurePage/index.vue` | Email code + password confirm UI |
| `app/frontend/frontend/components/Security/ChangePasswordForm/index.vue` | Simplified form |
| `app/frontend/shared/components/OauthBtn/index.vue` | Disconnect mode, redirect-back origin |
| `app/frontend/shared/components/SocialLogins/index.vue` | Disconnect handling, sorting |
| `db/migrate/20260417123936_add_password_set_manually_to_users.rb` | Column + timestamp backfill |

## Not in scope (deferred)

- **2FA via OAuth** — using provider as a second factor

## Discovery Log

- **2026-04-17** Initial research and plan creation
- **2026-04-17** Implementation started with OAuth re-auth approach
- **2026-04-18** Refactored to email confirmation (simpler, no provider dependency)
- **2026-04-18** Refactored to 6-digit code (no new tabs needed)
- **2026-04-18** Added OAuth disconnect, username sanitization, redirect-back fix

## Progress

- [x] Phase 1 — Database migration
- [x] Phase 2 — Email code confirmation
- [x] Phase 3 — Simplify password change
- [x] Phase 4 — Disconnect OAuth connections
- [x] Phase 5 — Expose fields and sanitize usernames
- [x] Phase 6 — SecurePage UI
- [x] Phase 7 — ChangePasswordForm
- [x] Phase 8 — OAuth disconnect UI
- [x] Phase 9 — Misc improvements and i18n
