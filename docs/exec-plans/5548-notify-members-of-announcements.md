# Notify fleet members when an announcement is posted

Working plan for #5548. Decisions live in the issue body. Deleted before the PR merges. Stacked on `feat/5541-fleet-dashboard-online-announcements-health`.

## Goal
Posting a fleet announcement tells every other member through their notification channels.

## What changed

### Phase 1 — Notification type
1. `fleet_announcement_posted` in the `Notification` enum and `TYPES`. The channels are app, mail (generic mailer), push and Discord DM, with push and mail off by default.
2. A `NotificationRecordReference` entry for `FleetAnnouncement` that carries `fleetSlug`, so the "open fleet" action appears.
3. Title and body in all 7 `notifications.yml` files. Labels and a settings group in all 7 `labels.json` files, plus `PRIMARY_ACTIONS`.

### Phase 2 — Fan-out
1. `FleetAnnouncement` enqueues `Notifications::FleetAnnouncementPostedJob` from `after_create_commit`, so every path that creates one notifies.
2. The job writes every kept, accepted member except the author a row, each in their own locale, with one `insert_all` per 1000 members against the partial unique index `index_notifications_on_fleet_announcement_recipient`. Delivery goes through `Notifications::BulkDelivery`, which was extracted from `Announcements::NotifyBatchJob`.
3. Deleting an announcement deletes its notifications (`dependent: :delete_all`).

### Phase 3 — Schema and CI
1. Regenerate the schema, AsyncAPI and clients, and add oasdiff-ignore lines for the new enum values, generated with the pinned 1.18.1.

## Key files

| File | Role |
|------|------|
| `app/models/notification.rb` | Enum and `TYPES` |
| `app/jobs/notifications/fleet_announcement_posted_job.rb` | Fan-out |
| `app/lib/notifications/bulk_delivery.rb` | Batched preferences and delivery, shared with `Announcements::NotifyBatchJob` |
| `app/lib/notification_record_reference.rb` | Record reference for the "open fleet" action |
| `lib/discord/event_announcement.rb` | Discord targets |
| `app/frontend/frontend/pages/settings/notifications.vue` | Preference groups |
| `app/frontend/frontend/composables/useNotificationActions.ts` | `PRIMARY_ACTIONS` |

## Discovery Log

- **2026-10-10** A research pass mapped the pipeline. There is no per-type icon registry, so the icon is a full class passed to `notify!`. The event and contract subscribers pass bare names (`"calendar"`), which looks like a bug, so I won't copy it.

- **2026-10-10** After review, the Discord channel post was dropped (see the issue). The job now retries, and skips members already notified for this record, so a failure outside the per-member rescue no longer loses the fan-out.
- **2026-10-10** A code review found that the per-member rescue swallowed every error, so retries almost never ran, and that "once per member" had no index behind it. The job now inserts in bulk against a unique index and lets errors raise. Retries are therefore safe. Discord DM is now `false` in the defaults explicitly. Reviving an expired announcement still notifies nobody, by decision.
- **2026-10-10** oasdiff 1.18.1 reports 12 warnings: the new `NotificationTypeEnum` and `NotificationRecordTypeEnum` values in notification responses. All are in the ignore list, and three runs passed against both the base branch and main.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
