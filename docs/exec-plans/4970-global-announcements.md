# Global announcements — one admin form, four channels

Issue: #4970

## Goal

An admin writes an announcement once and it reaches the Discord updates channel, X.com,
Bluesky and the in-app notification inbox (with e-mail for readers who opted in), with
per-channel delivery status visible afterwards.

## Context

Four halves of this already exist and none of them are joined up.

**Discord.** `Discord::Webhook` (`lib/discord/webhook.rb`) posts `**title**\nmessage\nurl` to
`Rails.application.credentials.discord_updates_endpoint` and returns early when that is blank.
`NewShip`, `ShipOnSale` and `NewSupporter` subclass it and override `get_title`/`get_message`/`get_url`.

**Bluesky.** `lib/bsky/post.rb` wraps `bskyrb` and has no caller anywhere in the tree. It
reads `bsky_handle` / `bsky_app_password` / `bsky_endpoint` from credentials **in the
constructor**, so an unconfigured install raises rather than no-opping.

**X.com.** Nothing. No gem, no credentials, no client.

**In-app.** `Notification` (`app/models/notification.rb`) carries a `TYPES` table keyed by
notification type — retention, channel list, an optional mailer lambda, and preference
defaults. `Notification.notify!` reads the reader's `NotificationPreference` and fans out to
app (ActionCable), mail (the lambda) and Discord DM. `NotificationPreference::CHANNEL_DEFAULTS`
is the single source of truth for the channel set.

### Two facts that shape the delivery design

**Existing users have no preference row for a new type.** `User#create_default_notification_preferences`
is an `after_create` hook, so the ~57.6k accounts that already exist will have no
`announcement` row. `NotificationPreference.for` returns an unsaved record carrying the
defaults, which is correct — but it means the fan-out cannot assume a row per user and has to
fall back to defaults for the misses.

**`Notification.notify!` is one reader at a time.** A `SELECT` for the preference, an `INSERT`
for the notification, then a broadcast. At 57.6k readers that is ~115k round trips in one job.
The fan-out batches instead: one preference query and one `insert_all` per 1,000 readers,
across jobs.

### Why mail is opt-in

57.6k confirmed users. An opt-out default is ~57k Postmark messages for every announcement,
which is both a cost and a deliverability event. `preference_defaults` for the type is
`{app: true, mail: false, push: false, discord: false}`, so mail reaches only readers who went
and turned it on.

### Why web push is not here

`notification_preferences.push` exists and **nothing delivers to it**: no VAPID keys in
credentials, no subscriptions table, no `push` listener in the service worker, no `:push` in
any type's channel list. Adding it is a subsystem — permission prompt, subscription lifecycle,
key rotation — that benefits all 40 notification types rather than this one. Decided out of
scope with the user on 2026-09-16; the toggle stays as inert as it already is.

## Design

### Two tables

`announcements` holds the content and the channel selection; `announcement_deliveries` holds
one row per channel with its own status, external id and error.

A separate table rather than status columns on `announcements`, because the four channels fail
independently and asymmetrically — X can be rate-limited while Bluesky succeeds — and a retry
has to be per channel. Columns would mean `discord_status`, `discord_error`, `discord_posted_at`
four times over, and no place to put the attempt count.

```
announcements
  title, body (markdown), link, icon
  discord_parts (ordered messages), social_parts (ordered posts)
  status: draft | scheduled | publishing | published | failed
  publish_at, published_at, recipients_count
  notify_users, post_discord, post_bluesky, post_x  (booleans)
  admin_user_id (author)

announcement_deliveries
  announcement_id, channel (in_app|discord|bluesky|x)
  status (pending|succeeded|failed|skipped), external_id, error, delivered_at, attempts
  unique (announcement_id, channel)
```

### Publishing

`Announcements::PublishJob` moves the announcement to `publishing`, then dispatches:

- one `Announcements::PostSocialJob` per selected social channel
- `Announcements::FanOutJob`, which walks `User.confirmed` in batches of 1,000 and enqueues a
  `Announcements::NotifyBatchJob` per batch

Each batch job loads the preference rows for its user ids in one query, merges the type
defaults over the misses, `insert_all`s the notification rows, broadcasts to the app-enabled
readers and enqueues mail for the mail-enabled ones.

`status` becomes `published` once dispatch completes — not once every batch lands. The
per-channel rows in `announcement_deliveries` are what carry outcome; a single status on the
parent cannot say "Discord posted, X failed".

### Scheduling

`publish_at` plus a five-minute `Announcements::PublishScheduledJob` in
`config/sidekiq_schedule.yml`. Not a per-announcement `perform_at`, because an admin editing
or deleting a scheduled announcement would leave an orphaned job that still fires.

### Composition, per channel

Both composers return an **ordered list**, not a string.

`Announcements::SocialPosts` builds the posts for a given character limit — 300 for Bluesky,
280 for X. `Announcements::DiscordMessages` builds the messages for a 2,000-character channel.

When the author wrote `social_parts` / `discord_parts` they are posted verbatim and in order:
where a thread breaks, and which post carries the link, are editorial decisions, and a composer
that re-wrapped them would move a boundary somebody chose. Without them, social falls back to
one composed post (title, first paragraph, link) and Discord packs the body into as many
messages as it takes, on paragraph boundaries.

Truncation is the fallback of last resort and never touches the link: a cut URL is not a link,
and the body is the part a reader can lose without losing the way to the rest.

**This replaced a single truncated message per channel**, which was wrong for anything longer
than a short announcement. The Fleet Ops beta copy (#4978) is two Discord messages (3,524
characters) and a two-post thread; under the original design Discord lost everything past 1,800
characters and the second social post was never posted at all. What that dropped was the
supporter-features line and the personal-inventories carve-out — the D15 copy constraint from
`premium-fleet-features.md`, which is the one piece a later migration to a billing provider
cannot undo, because it is what the customer was told they were doing.

Threading on the platforms:

- **X** — every post after the first names the one before it via `reply.in_reply_to_tweet_id`.
- **Bluesky** — a reply names both its `parent` and the thread's `root`. bskyrb's own
  `create_post_or_reply` sets them to the same post, which is right for the second post and
  wrong for every one after it, so the record is built here instead.
- **Discord** — sequential webhook executes, in order.

The delivery's `external_id` records the **first** post, which is what addresses a thread.

### X.com client

`XCom::Post` (`lib/x_com/post.rb`), OAuth 1.0a HMAC-SHA1 against `POST /2/tweets`. OAuth 1.0a
rather than OAuth 2.0 user-context because the latter needs a refresh-token lifecycle for what
is a single service account. Named `XCom` rather than `X` to keep a one-letter constant out of
the global namespace.

`configured?` on each of the three clients, checked before dispatch, so an unconfigured channel
records `skipped` instead of raising.

## Phases

1. **Data model** — migration, `Announcement`, `AnnouncementDelivery`, factories, model tests.
   Extended afterwards with `discord_parts` / `social_parts` (see *Composition, per channel*).
2. **Notification type** — `announcement` in `Notification::TYPES` + enum, `AnnouncementMailer`,
   MJML template, backend locales (7), `labels.notificationTypes` + settings group (7).
3. **Delivery** — `Announcements::{Publish,FanOut,NotifyBatch,PostSocial,PublishScheduled}Job`,
   `Announcements::SocialPosts`, `Announcements::DiscordMessages`,
   `Discord::Announcement`, `Bsky::Post.configured?`,
   `XCom::Post`, job and lib tests.
4. **Admin API** — `Admin::Api::V1::AnnouncementsController` (+ `publish`, `retry_delivery`),
   `Admin::AnnouncementPolicy`, the `announcements` privilege, routes, jbuilder views, OpenAPI
   components, integration tests.
5. **Admin frontend** — index / create / edit pages, channel pickers, delivery status panel,
   nav entry, translations (7).
6. **Regeneration** — `bin/generate-schema`, orval, `standardrb --fix`, `pnpm lint:fix`,
   `pnpm lint:ts`, targeted Ruby and Vitest runs.

## Risks

- **Enum widening.** Adding `announcement` to `Notification.notification_types` widens
  `NotificationTypeEnum` in the public schema. `api-schema-breaking` diffs against `main`, so
  expect it to flag the added enum value.
- **Privilege labels.** A new privilege ships as `translation missing` in all seven locales
  unless `labels.admin.resourceAccess.privileges` is extended in each. `labels.json` has
  duplicate keys — edit it as text, never via a JSON round-trip.
- **Fan-out cost.** 58 batch jobs and ~57.6k inserts per announcement. Bounded by running on
  the `notifications` queue and batching; the broadcasts are publishes to streams with no
  subscribers for the ~99% of readers who are offline.
