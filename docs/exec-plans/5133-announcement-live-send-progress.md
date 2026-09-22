# Announcement list: live send progress over websockets, and rows instead of a table

## Goal

An admin who presses **Publish** watches the announcement's status and each of its four delivery channels settle on screen, without reloading — and reads the list as rows rather than as a table.

## Context

Publishing dispatches four independent channels (`Announcements::PublishJob` → `PostSocialJob` per social channel, `FanOutJob` → ~58 `NotifyBatchJob`s for the in-app one). Each reports into its own `AnnouncementDelivery` row from a background job, so nothing the admin is looking at changes: the deliveries cell keeps saying `pending` until a reload or an unrelated refetch.

`_announcement.jbuilder` already opts out of `json.cache!` for exactly this reason. The missing half is a push.

Resolves #5133

## Decisions

### D1 — One channel per admin user, not per announcement

`AdminAnnouncementsChannel` streams for `current_admin_user`, like every other channel in the app. `useSubscription` has no way to pass params — the type is `Channel<Record<string, never>, T>` — and the list shows 25 announcements at a time, so a per-record channel is not reachable from the client anyway.

Rejected: a single global `ActionCable.server.broadcast("announcements", …)` stream, as `Model` uses. Announcement payloads carry unpublished drafts and author names; the stream has to be behind the admin identity.

### D2 — Broadcast the whole announcement payload

The jbuilder embeds `deliveries`, so one render carries the row and everything under it. The frontend swaps it into the cache wholesale and needs no merge logic.

Rendered once per broadcast round and reused across admins — `Import#notify_admin` re-renders inside its `find_each`, which is one `ActionController::Renderer` round trip per admin for an identical payload.

### D3 — Patch the query cache, don't invalidate it

A publish emits up to ten broadcasts. Invalidating on each would refetch the list ten times and reorder it under whoever is reading it. `useAdminNotificationInvalidation.patchCached` already makes this call for the notification list; this follows it.

The detail page's `getAnnouncementQueryKey(id)` is patched from the same handler, so `[id]/edit` and the list stay in step.

### D4 — Only broadcast on columns the payload carries

`AnnouncementDelivery#record_part!` saves once per posted thread part and `posted_parts` is not serialised, so broadcasting every save would push identical payloads — up to 30 of them for a three-channel thread. The `after_commit` filters on `saved_changes`.

On the announcement side the filter is narrower still: `status`, `published_at`, `recipients_count`, `last_tested_at`. An edit made through the form is already reflected by the mutation's own invalidation, and re-broadcasting it would push a title change into another admin's open edit form.

### D5 — `after_commit`, not a call site in each job

The transitions happen in four places (`PublishJob`'s pending writes, `PostSocialJob`'s `succeed!`/`fail!`/`skip!`, `NotifyBatchJob`'s `settle`, and the controller's retry). A callback on the row is the one place all four pass through, and it covers the retry path without the controller knowing about the channel.

The delivery's callback reloads its announcement rather than reading through the association: `delivery_for` builds the row through `deliveries.find_or_initialize_by`, and the payload has to contain the transition that just committed.

### D6 — `RowList`, with the sorts moved to a `SortBar`

The deliveries cell is a stacked list of channel, status, timestamp, error and a retry button — which is why it and the recipients column are both `mobile: false` today, i.e. the two things a publish changes are invisible on a phone exactly while it is happening. As a row the deliveries sit on their own line and survive the narrow viewport.

`BaseTable`'s sortable headings go with it, so the two sorts (`title`, `publishedAt`) move to a `SortBar` beside the list, as the commodities catalogue does.

## What changed

### Phase 1 — The channel

1. `app/channels/admin_announcements_channel.rb` — streams for `current_admin_user`, rejects without one.
2. `Announcement#broadcast_to_admins` + `#jbuilder_template_path` — renders `admin/api/v1/announcements/announcement` once, fans out to every `AdminUser`.
3. `after_commit` on `Announcement` and on `AnnouncementDelivery`, filtered per D4.
4. `test/asyncapi/admin_announcements_channel_test.rb` declares the channel and the broadcast; `bin/generate-asyncapi` + `bin/generate-clients` regenerate the document and the client.

### Phase 2 — The subscription

1. `app/frontend/admin/composables/useAnnouncementUpdates.ts` — patches every `getAnnouncementsQueryKey()` list and the record's own query; resyncs on reconnect.
2. Subscribed from `announcements/index.vue` and `announcements/[id].vue`.

### Phase 3 — Rows

1. `app/frontend/admin/components/Announcements/Row/index.vue` (+ `.scss`, `.spec.ts`).
2. `announcements/index.vue` swaps `BaseTable` for `RowList` + `SortBar` + `RowsSkeleton`.
3. `useAnnouncementSortFields` for the sort line.

## Intent Verification

- [ ] **Status moves live** — publishing from one browser moves the row to `publishing` and then `published` in a second browser with no reload
- [ ] **Deliveries settle live** — each channel's pill goes `pending` → `succeeded` / `failed` / `skipped` as its job finishes
- [ ] **Retry reports live** — a retry from the list shows its outcome without a refetch
- [ ] **The detail page follows** — `[id]/edit` shows the same delivery states from the same subscription
- [ ] **No polling** — no interval or `refetchInterval` is introduced
- [ ] **Rows** — the list renders `RowList` rows, sortable by title and published date, and the deliveries are visible on a narrow viewport
- [ ] **Contract** — `bin/generate-asyncapi` leaves no diff after the channel test is in place

## Key files

| File | Role |
|------|------|
| `app/channels/admin_announcements_channel.rb` | The new per-admin stream |
| `app/models/announcement.rb` | `broadcast_to_admins`, jbuilder path, `after_commit` |
| `app/models/announcement_delivery.rb` | `after_commit`, filtered on payload columns |
| `app/views/admin/api/v1/announcements/_base.jbuilder` | The payload the broadcast carries |
| `test/asyncapi/admin_announcements_channel_test.rb` | The AsyncAPI declaration and its assertion |
| `app/frontend/admin/composables/useAnnouncementUpdates.ts` | Cache patching |
| `app/frontend/admin/components/Announcements/Row/index.vue` | The row |
| `app/frontend/admin/pages/announcements/index.vue` | `BaseTable` → `RowList` |

## Not in scope (deferred)

- **X API credentials** — `XCom::Post` reads four keys that exist in no environment, so that delivery is `skipped` everywhere. Being added to the production credentials by hand, outside this branch.
- **Fan-out progress as a figure** — the in-app delivery settles once, at the end; there is no per-batch counter to show, and adding one means a write per batch.
- **Create and destroy broadcasts** — a second admin adding or deleting an announcement still needs a refetch. This is about a send in flight.

## Discovery Log

- **2026-09-21** Initial research and plan creation.
- **2026-09-22** All three phases landed. The row's layout was checked with the
  static CSS harness rather than a dev server (this worktree has none, and the
  admin app is behind a login): no horizontal scroll and nothing escaping the
  viewport at 1280 / 768 / 430 / 400px, the title truncating with an ellipsis
  from 430px down, and the deliveries block 8px under the head at every width.
  `bin/generate-schema` leaves only the known macOS `components.parameters`
  reordering, which was reverted.

## Progress
- [x] Phase 1 — the channel, the broadcasts and the AsyncAPI declaration
- [x] Phase 2 — the subscription and the cache patching
- [x] Phase 3 — the row, the sort bar and the page rewrite
