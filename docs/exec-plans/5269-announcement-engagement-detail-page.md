# Announcement engagement and a detail page

Working plan for #5269. Decisions live in the issue body. Deleted before the PR merges.

## Goal

The admin announcement list shows a one-line delivery summary per row, and a new detail page shows each channel's delivery with its engagement (Bluesky counts, Discord reactions, X link).

## What changed

### Phase 1 — Backend: capture and store
1. Migration: `announcement_deliveries.engagement` (jsonb, null) and `engagement_fetched_at` (datetime).
2. `Discord::Webhook#run` yields the created message when a subclass asks to wait (`wait?`); `Discord::Announcement` waits, and `PostSocialJob` records `message_id`/`channel_id` per part.
3. `Bsky::Engagement` — public AppView `app.bsky.feed.getPosts`, 25 URIs per call, sums likes/reposts/quotes and replies minus the thread's own chain.
4. `Discord::Engagement` — bot `GET channels/:id/messages/:id`, reactions merged by emoji; guild id from `GET channels/:id` for the jump link.
5. `Announcements::RefreshEngagementJob` (one delivery) and `Announcements::RefreshEngagementSweepJob` (hourly; hourly refresh under 2 days, daily up to 30 days, then stops).
6. `POST /announcements/:id/refresh-engagement` in the admin API.
7. Payload: `engagement`, `engagementFetchedAt`, `url` per delivery; `engagement` added to the broadcast attributes; regenerate REST + AsyncAPI schemas.

### Phase 2 — Frontend
1. `AnnouncementRow`: delivery summary ("3/3 sent", failures and pending called out) instead of `AnnouncementDeliveries`; title links to the detail page.
2. Detail page at `/announcements/:id/` (first child route): content, actions with labels, deliveries with engagement and a refresh button.
3. Translations in all seven locales.

## Intent Verification

- [ ] List row shows the summary and no drill-down
- [ ] Detail page shows status, attempts, error and retry per channel
- [ ] Bluesky shows likes, reposts, replies, quotes
- [ ] Discord shows reactions per emoji
- [ ] X shows a link and no counts
- [ ] Sweep cadence: hourly < 2 days, daily < 30 days, none after
- [ ] Manual refresh queues a refresh and the counts arrive over the cable

## Key files

| File | Role |
|------|------|
| `app/models/announcement_delivery.rb` | engagement columns, due scope, links |
| `app/jobs/announcements/post_social_job.rb` | records Discord message ids |
| `lib/discord/webhook.rb`, `lib/discord/announcement.rb` | `wait: true` |
| `lib/bsky/engagement.rb`, `lib/discord/engagement.rb` | fetchers |
| `app/jobs/announcements/refresh_engagement*_job.rb` | refresh |
| `app/views/admin/api/v1/announcements/_announcement.jbuilder` | payload |
| `app/frontend/admin/components/Announcements/*` | row summary, deliveries, engagement |
| `app/frontend/admin/pages/announcements/[id]/show.vue` | detail page |

## Not in scope (deferred)

- **X counts** — no free read API; decided in the issue.

## Discovery Log

- **2026-09-28** Discord webhook executes without `wait`, so no message id exists for past posts; Bluesky already records every part's `uri`.
- **2026-09-28** Faraday's default nested encoder collapses repeated `uris=` to the last value; the Bluesky client uses `FlatParamsEncoder`. WebMock normalises the same way unless `query_values_notation = :flat_array`.
- **2026-09-28** `engagementTrackable` on the delivery payload separates "not fetched yet" from "never will be" (X, and Discord posts without message ids).
- **2026-09-28** The parent `:id/` route's redirect was dropped: its first child is now the empty-path detail route.

## Progress
- [x] Phase 1
- [x] Phase 2
- [ ] e2e + PR
