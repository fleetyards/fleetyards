# Notification Center Frontend

The backend from [notification-center-backend.md](notification-center-backend.md) persists every user notification, but the frontend still throws them away: `useUpdates` turns an incoming `UserNotificationsChannel` message into a toast and nothing else. There is no page, no bell, no unread badge — a notification missed while the tab was closed is gone.

The admin app already has the thing this plan builds: `admin/pages/notifications.vue` with a two-pane list/reading layout, inbox and archive tabs, a filter sidebar, unread-first sorting and a bell in the navigation carrying the unread count. This plan gives the user-facing app the same center, and closes the four gaps in the public API that stand between the two.

## Gap analysis

| Capability | Admin | User (before) | Plan |
|---|---|---|---|
| List, paginate, filter by type/read | yes | yes | — |
| Mark read, mark all read, delete, delete all | yes | yes | — |
| Unread count endpoint | `GET unread-count` | missing | Phase 2 |
| Mark as unread | `PUT :id/unread` | missing | Phase 2 |
| Archive / unarchive | `archived_at` + 2 endpoints | column missing | Phase 1–2 |
| Full-text search | `search_cont` over title/body | not ransackable | Phase 1–2 |
| Unread-first sorting | `unread desc` ransacker | plain `created_at` | Phase 1–2 |
| Severity | `severity` enum | no such concept | out of scope |
| Occurrences / dedupe | `dedupe_key`, `occurrences` | no such concept | out of scope |

Severity and dedupe stay admin-only on purpose: they exist because an import job reports the same failure every night to an operator. A user's notifications are events that happened once, and each is as important as the reader decides.

## Decisions

### D1 — A page with a bell, not a dropdown

The center is a route (`/notifications/`) reached from a bell in the navigation footer, mirroring the admin. A dropdown panel would be a second surface listing the same records with its own truncation rules, and the reading pane — where a notification's body actually becomes readable — has nowhere to go inside one.

### D2 — Parity in the API, not in the payload

The public endpoints gain the four missing operations so the two centers behave alike, but `Notification` keeps its own shape. No `severity`, no `occurrences` — adding fields the model cannot populate to make the schemas rhyme is dead weight in every client.

### D3 — The frontend components are siblings, not shared

`frontend/components/Notifications/*` is written against `Notification`, `admin/components/Notifications/*` stays against `AdminNotification`. The two payloads differ (severity, occurrences, archived semantics) and a shared component would carry both shapes plus the branches to tell them apart. What is genuinely shared already is: `FilteredList`, `Panel`, `Btn`, `Paginator`, `useFilters`, `usePagination`.

### D4 — One subscription, in the navigation

`useUpdates` already subscribes to `UserNotificationsChannel` app-wide for the toast. The invalidation of the list and count queries hangs off that same handler rather than a second subscription from the page, the way `useAdminNotificationUpdates` documents it — two subscriptions would double every toast.

### D5 — Retention archives rather than deletes

`expires_at` used to end a notification: the controller's `active` scope hid it
and the nightly cleanup deleted it. With an archive in place that is the wrong
shape - the date now files a notification into the archive, and a second term
(`ARCHIVE_RETENTION`, 90 days from `archived_at`) is what deletes it. The tabs
apply the rule themselves rather than waiting for the job, so a notification
moves on its date and not at 3am; the job only writes down what the tabs
already show, and purges what has served the second term. The reading pane
names whichever date is next: "moves to the archive" in the inbox, "deleted" in
the archive, off the new `deletesAt` field.

Deleting at all is a size question, not a product one: a notification exists per
event *per recipient*, its text is a snapshot, and the record it refers to lives
on independently. A quarter in the archive is the compromise.

### D6 — The settings page is a matrix in the design system

`/settings/notifications` was a bare `<table>` with its own colours and a
`FormToggle` per cell. It keeps the matrix - a channel per column is the only
layout that shows 24 types without scrolling - but inside `Panel` /
`PanelHeading` / `PanelBody`, with a group switch per channel, and the `push`
column hidden for as long as no type reports `pushAvailable`. On a phone the
columns collapse and each switch names its own channel.

### D7 — The toast becomes a way in

An arriving notification is now a record that persists, so its toast links to the center (`to: { name: "notifications" }`) instead of only fading. Unlike the admin's, it keeps its timeout: a user's toast interrupts browsing rather than reporting an operational failure that must not be missed.

---

## Progress

- [x] Phase 1 — Model: archive, unread-first, searchable
- [x] Phase 2 — Controller, routes, policy, views
- [x] Phase 3 — API components, integration tests, schema
- [x] Phase 4 — Route, page and components
- [x] Phase 5 — Navigation bell and live updates
- [x] Phase 6 — Visual test page and e2e coverage
- [x] Phase 7 — Lint, typecheck, test run
- [x] Phase 8 — Retention archives instead of deleting
- [x] Phase 9 — Settings page redesign

---

## Phase 1: Model — archive, unread-first, searchable

### Migration

**Create** `db/migrate/YYYYMMDDHHMMSS_add_archived_at_to_notifications.rb`

```ruby
add_column :notifications, :archived_at, :datetime
add_index :notifications, [:user_id, :archived_at]
```

### Modify `app/models/notification.rb`

Mirroring `AdminNotification`:

- Scopes `inbox` (`archived_at: nil`) and `archived`
- `ransack_alias :search, :title_or_body`
- `ransacker :unread, type: :boolean` over `notifications.read_at IS NULL`
- `ransackable_attributes` gains `archived_at title body search unread`
- `archived?`, `archive!`, `unarchive!`, `mark_as_unread!`

### Test

**Modify** `test/models/notification_test.rb` — archive/unarchive round trip, `mark_as_unread!`, the `unread` ransacker ordering, `search` matching title and body.

## Phase 2: Controller, routes, policy, views

### Modify `app/controllers/api/v1/notifications_controller.rb`

- `index` defaults `archived_at_null` to `true` and prepends `unread desc` to the sorts, as the admin does
- New actions `unread_count`, `unread`, `archive`, `unarchive`; `read` renders `:show` rather than its own template
- `read_all` clears the inbox only, leaving a deliberately unread archived notification alone
- Permitted query params gain `archived_at_null` and `search_cont`
- Doorkeeper scopes: `unread_count` joins the `notifications:read` list, the three mutating actions join `notifications:write`

### Modify `app/policies/notification_policy.rb`

`alias_rule` gains `:unread?, :archive?, :unarchive?, :unread_count?`.

### Modify `config/routes/api/notifications_routes.rb`

```ruby
resources :notifications, only: %i[index destroy] do
  member do
    put :read
    put :unread
    put :archive
    put :unarchive
  end
  collection do
    get "unread-count", to: "notifications#unread_count"
    put "read-all", to: "notifications#read_all"
    delete "destroy-all", to: "notifications#destroy_all"
  end
end
```

### Views in `app/views/api/v1/notifications/`

- `_base.jbuilder` gains `archived` and `archived_at`
- `read.jbuilder` becomes `show.jbuilder` (one template for read/unread/archive/unarchive)
- New `unread_count.jbuilder`

## Phase 3: API components, integration tests, schema

- `V1::Schemas::Notification` — add `archived`, `archivedAt`
- `V1::Schemas::Queries::NotificationQuery` — add `archivedAtNull`, `searchCont`
- **Create** `V1::Schemas::NotificationUnreadCount` (`{count: integer}`)
- **Modify** `test/integration/api/v1/notifications_test.rb` — one case per new action, referencing components by class. Two collection paths on one verb need an explicit `api_path:` in the assertion
- `bundle exec standardrb --fix`, then `./bin/generate-schema`

## Phase 4: Route, page and components

### Routing

- `app/frontend/frontend/pages/routes.ts` — `/notifications/`, name `notifications`, `needsAuthentication: true`, `nav: "main"`
- `app/frontend/frontend/types/routes.ts` — add `"notifications"` to `FrontendSimpleRoutes`
- `config/routes/frontend_routes.rb` — `get "notifications", to: "base#index"` so a reload on the deep link is served by the SPA

### Page

**Create** `app/frontend/frontend/pages/notifications.vue` — the admin page minus severity and occurrences: inbox/archive tabs off `?t=archive`, newest/oldest toggle off `?s`, keyboard navigation between rows, `patchCached` on read so the open notification does not jump, header actions (read all, delete all) teleported to `#header-right`.

### Components

**Create** under `app/frontend/frontend/components/Notifications/`:

- `ListItem/index.vue` — icon, title, type label, timestamp, hover actions (archive/unarchive, delete)
- `Detail/index.vue` — reading pane with the body, an "open" button for `notification.link`, mark-unread, archive, delete, and the expiry as a fact row
- `FilterForm/index.vue` — search field teleported to `#header-left`, unread-only radio, type filter group

**Create** `app/frontend/frontend/composables/useNotificationFilters.ts` — `useFilters<NotificationQuery>` with the tab key ignored.

**Create** `app/frontend/frontend/composables/useNotificationUpdates.ts` — `invalidate`, `invalidateUnreadCount`, `patchCached`, matching the admin composable.

### i18n

Only `en` is maintained here — the other locales come back through Crowdin. Type labels already exist as `labels.notificationTypes.*` (the settings page uses them), so the center reuses them rather than adding a second list. New keys: `nav.notifications`, `headlines.notifications.index`, `labels.notifications.*` (inbox, archive, unreadOnly, status, type, selectPrompt, noBody, expires), `actions.notifications.*`, `messages.notifications.*`, `messages.confirm.notifications.destroyAll`, `filters.notifications.search`.

## Phase 5: Navigation bell and live updates

- **Create** `app/frontend/frontend/components/Navigation/NotificationsNav/index.vue` — `NavItem` with the bell icon and the unread count as its badge, rendered only when authenticated
- **Modify** `Navigation/index.vue` (footer, above settings) and `Navigation/Mobile/index.vue`
- **Modify** `app/frontend/frontend/composables/useUpdates.ts` — `handleUserNotification` invalidates the list and count queries and gives the toast a link to the center

## Phase 6: Visual test page and e2e coverage

- **Create** `app/lib/notification_examples.rb` — the fixture set both the visual page and the e2e scenario build from, mirroring `AdminNotificationExamples`
- **Create** `app/frontend/frontend/pages/visual-tests/notifications.vue` plus its route and nav entry
- **Create** `test/playwright/app_commands/scenarios/notifications.rb` and `test/playwright/e2e/Notifications.spec.ts` — list renders, one click opens and marks read, mark unread, archive moves the row to the other tab, delete, filter by unread

## Phase 7: Lint, typecheck, test run

1. `bundle exec standardrb --fix`
2. `pnpm lint:fix`
3. `bin/vite build --mode=test` once in this fresh worktree, then `pnpm lint:ts` (auto-imports have no types before a build; judge it by the exit code, not by grepping for "error TS")
4. `bin/rails test test/models/notification_test.rb test/integration/api/v1/notifications_test.rb`
5. `./bin/generate-schema` and confirm the cable document still validates

## Phase 8: Retention archives instead of deleting

- `Notification` — `ARCHIVE_RETENTION`, the `purgeable`, `pending` and `filed`
  scopes, `archive_expired!` and `deletes_at`
- `Api::V1::NotificationsController` — the tab picks `pending` or `filed`, and
  `archived_at_null` never reaches ransack; the unread count and read-all follow
  `pending`
- `Cleanup::NotificationsJob` — archives first, then purges the served term.
  Admin notifications keep their delete-on-expiry behaviour: an operational
  report has no reader who wants it back
- `deletesAt` in the payload, the component and the reading pane
- Tests: model scopes, the job, and a request case per tab

## Phase 9: Settings page redesign

- `pages/settings/notifications.vue` rewritten against `Panel`/`PanelHeading`/
  `PanelBody`, a group switch per channel, optimistic cache patching, and the
  push column gated on `pushAvailable`
- `FormToggle` carries `margin-bottom: 1rem` for form columns, which a table
  cell has to undo - that margin was the whole of the row spacing problem
- New keys: `labels.notificationTypes.allInGroup`,
  `texts.settings.notifications.hint`, `actions.notifications.openCenter`,
  `messages.updateNotifications.failure`

## Key files

| File | Role |
|---|---|
| `app/models/notification.rb` | Archive, unread ransacker, search alias |
| `app/controllers/api/v1/notifications_controller.rb` | The four new actions |
| `app/policies/notification_policy.rb` | Authorization for them |
| `config/routes/api/notifications_routes.rb` | Routes |
| `app/api_components/v1/schemas/notification*.rb` | Schema parity |
| `app/frontend/frontend/pages/notifications.vue` | The center |
| `app/frontend/frontend/components/Notifications/*` | List row, reading pane, filters |
| `app/frontend/frontend/composables/useNotificationUpdates.ts` | Cache invalidation |
| `app/frontend/frontend/components/Navigation/NotificationsNav/index.vue` | Bell and badge |
| `app/frontend/frontend/composables/useUpdates.ts` | Toast plus invalidation |

## Not in scope

- **Push notifications** — the `push` preference column is still unwired
- **Severity and dedupe for user notifications** — see D2
- **A dropdown panel at the bell** — see D1
- **Merging the center with `/settings/notifications`** — preferences stay their own page; the center links to it

## Discovery Log

- **2026-08-27** The nav badge and the inbox tab's count were both ovals, and in
  the collapsed nav the badge sat across the middle of the bell rather than on
  its corner. Both were width-without-height; the dot moved from
  `inset-inline-start: 10px` to 18px, which is where a 30px icon box ends.
- **2026-08-27** e2e locally: the Rails test server takes its asset host from
  `PORT`, so a build without `PORT=8280` bakes `localhost:3000` into the CSS and
  every font is blocked by CSP. A stale `pnpm dev:vite` on 3137 from an earlier
  non-CI run is worse - Rails proxies to it, the proxy times out, and the page
  reload-loops with no error anywhere.
- **2026-08-27** Rebased onto main after #4554. The branch was still named `feat/notification-center`, which belongs to the merged backend PR #3689, and is now `feat/notification-center-frontend`.
- **2026-08-27** The nav badge was an oval: `.nav-item-badge` set `min-width: 20px` against a `line-height: 18px` and no height, so a single digit came out 20x18. Width and height are now the same number, and it only stretches into a pill from two digits on. Shared component, so the admin bell gets it too.
- **2026-08-27** e2e assets: `bin/vite build --mode=test` writes to `public/vite-dev` unless `RAILS_ENV=test` is also set - vite-ruby picks the output directory off the Rails env, not off `--mode`. Without it every page 500s on a missing favicon entry in the manifest.
- **2026-08-27** Plan written. Backend from the earlier plan is in place (24 types, preferences, cable); the frontend has no center at all, and the public API is missing unread-count, mark-unread, archive and search.
