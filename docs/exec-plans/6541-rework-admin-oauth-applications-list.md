# Rework the admin OAuth applications list: more data and phone support

Working plan for #6541. Decisions live in the issue body. Deleted before the PR merges.

## Goal

An admin can find, judge and act on OAuth applications from the list alone, on desktop and on a phone.

## What changed

### Phase 1 — API: sorting and usage count
1. `Oauth::Application::ADMIN_SORTING_PARAMS` / `DEFAULT_SORTING_PARAMS`, `OauthApplicationSortEnum`, `s` / `sorts` on `OauthApplicationQuery`, permitted and normalised in the controller
2. `Oauth::Application.with_authorized_users_count` (distinct resource owners holding an unrevoked token) selected in `index`, exposed as `authorizedUsersCount`, sortable
3. Notification link becomes `/oauth-applications/?aasmStateEq=pending` — the list's filters read camelCase top-level keys
4. Integration tests for filters, sorting and the count; regenerate schema + Orval clients

### Phase 2 — List page
1. `PageActions` instead of the `Teleport` create button
2. `OauthApplications/FilterForm` (name in the header, state select), wired through `useFilters`; `perPage` passed to the query
3. Columns: logo, name (+ redirect URI host), state (+ reviewer / date / rejection reason), owner (link that filters by `ownerIdEq`), scopes, authorized users, created, updated; sortable where the API allows
4. Phone: the name cell stacks logo, state, owner, scopes and review info, following the admin feedback list

### Phase 3 — Specs and translations
1. Vitest for the list (filter wiring, phone cell) and the filter form
2. Every new label in every locale

## Intent Verification

- [ ] `?aasmStateEq=pending` shows only pending applications; the notification lands there
- [ ] Logo, scopes, redirect URI, reviewer / review date / rejection reason, authorized users and updated-at are visible on desktop
- [ ] Sorting by name, state, created, updated and authorized users works
- [ ] On a 390px viewport each row carries state, owner, scopes and review info
- [ ] Create button folds into the phone page menu

## Key files

| File | Role |
|------|------|
| `app/frontend/admin/pages/oauth-applications/index.vue` | The list |
| `app/frontend/admin/components/OauthApplications/` | Actions, reject modal, new filter form |
| `app/controllers/admin/api/v1/oauth_applications_controller.rb` | Index filters / sorting |
| `app/models/oauth/application.rb` | Sorting params, count scope, notification link |
| `app/api_components/admin/v1/schemas/` | Query, sort enum, model schema |
| `app/views/admin/api/v1/oauth_applications/_base.jbuilder` | Response |
| `test/integration/admin/api/v1/oauth_applications_test.rb` | API tests |

## Not in scope (deferred)

## Discovery Log

- **2026-11-27** Authorised-users count rendered outside the jbuilder cache fragment: tokens change without touching the application.
- **2026-11-27** Initial research. List sent `q: {}`; notification used a snake_case `q[...]` link no list reads; `perPage` never reached the query.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [ ] Visual check, desktop and 390px, on the worktree dev server (port 8300)
