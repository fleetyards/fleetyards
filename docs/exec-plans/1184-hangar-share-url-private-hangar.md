# Hangar: Share URL for Private Hangar

Working plan for #1184. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A user with a private hangar can create, copy, rotate and delete a secret share link that lets anyone holding it view the hangar.

## Open questions
- None. URL shape (`?share=<token>`) and scope (hangar + groups + stats) are decided in the issue body. The share section stays visible even when the hangar is public, so a link survives switching to private.

## What changed

### Phase 1 — Token on the user
1. Migration: `users.hangar_share_token` (string, unique index).
2. `User#hangar_share_enabled?`, `ensure_/rotate_/clear_hangar_share_token!`, `generate_hangar_share_token` — mirror the calendar feed methods (`app/models/user.rb:557-581`), `SecureRandom.urlsafe_base64(32)`.

### Phase 2 — Manage endpoint
1. `Api::V1::Me::HangarSharesController` with `show`, `create`, `rotate`, `destroy` (template: `me/calendar_subscriptions_controller.rb`), Doorkeeper `user:read` / `user:write`.
2. Route `namespace :me { resource :hangar_share, path: "hangar/share" ... post :rotate }`.
3. Jbuilder `{ enabled, shareUrl }` + hand-written schema component.
4. Integration tests (`me_hangar_share_{show,create,rotate,destroy}_test.rb`).

### Phase 3 — Token grants read access
1. `Public::UserPolicy#show?` / `show_stats?` accept a share token via authorization context; compare with `ActiveSupport::SecurityUtils.secure_compare`.
2. Pass the token from `public/hangars`, `hangar_stats`, `hangar_groups`, `public/users` controllers.
3. Tests: valid token → 200 on a private hangar, wrong/cleared token → 404, policy tests.

### Phase 4 — Frontend
1. Share section in `pages/settings/hangar.vue` following `pages/settings/calendar.vue` (enable / copy / rotate with confirm / disable).
2. Public hangar page forwards the token to its API calls (`stores/publicHangar.ts`, stats, groups).
3. i18n in all 7 locales; regenerate schema + orval clients.

## Intent Verification

- [ ] **Create** — owner of a private hangar can generate a share URL in settings.
- [ ] **View** — a logged-out visitor with the URL sees the hangar; without it, still 404.
- [ ] **Delete** — after deletion (or rotation) the old URL returns 404.

## Key files

| File | Role |
|------|------|
| `app/policies/public/user_policy.rb` | Hangar read access rules |
| `app/models/user.rb` | Token methods; `with_hangar_readable_by` scope |
| `app/controllers/api/v1/public/hangars_controller.rb` (+ stats, groups) | Public hangar endpoints |
| `app/controllers/api/v1/me/calendar_subscriptions_controller.rb` | Token-management template |
| `app/frontend/frontend/pages/settings/hangar.vue` | Settings UI |
| `app/frontend/frontend/pages/settings/calendar.vue` | UI template |
| `app/frontend/frontend/pages/hangar/[username]/` | Public hangar pages |

## Not in scope (deferred)
- **Embed endpoint / Discord command via token** — they use the bulk scope; no clear need.

## Discovery Log

- **2026-10-08** Initial research and plan creation. `Frontend::HangarController#public` sets OG title/image without checking the policy — already leaks the flagship image for private hangars.
- **2026-10-08** openapi-ruby's minitest adapter treats every parameter declared at `api_path` level as a path parameter and strips it from the query — `share` had to be declared inside each `get` block. The app also drops undeclared query params, so the schema must be regenerated before the share tests can pass.
- **2026-10-08** `useFilters` spreads the whole route query into `q`; `share` is a `viewKeys` entry in `useHangarFilters` so it stays in the URL without reaching the API as a filter.
- **2026-10-08** Overlaps #5489 (fleetchart share button) in `pages/hangar/[username]/{index,stats}.vue` — textual conflicts only. Its share URL copies the whole query, so it forwards `share=` too; kept, since stripping it would hand out a 404.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
