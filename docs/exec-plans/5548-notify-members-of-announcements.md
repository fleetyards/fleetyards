# Notify fleet members when an announcement is posted

Working plan for #5548. Decisions live in the issue body. Deleted before the PR merges. Stacked on `feat/5541-fleet-dashboard-online-announcements-health`.

## Goal
Posting a fleet announcement tells every other member through their notification channels, and the fleet's Discord when it has one.

## What changed

### Phase 1 — Notification type
1. `fleet_announcement_posted` in the `Notification` enum and `TYPES`. The channels are app, mail (generic mailer), push and Discord DM, with push and mail off by default.
2. A `NotificationRecordReference` entry for `FleetAnnouncement` that carries `fleetSlug`, so the "open fleet" action appears.
3. Title and body in all 7 `notifications.yml` files. Labels and a settings group in all 7 `labels.json` files, plus `PRIMARY_ACTIONS`.

### Phase 2 — Fan-out
1. Instrument `fleet_announcement.posted` in `FleetAnnouncementsController#create`.
2. A subscriber, `Notifications::InApp::FleetAnnouncementSubscriber`, enqueues a job (`Notifications::FleetAnnouncementPostedJob`). The job notifies every kept, accepted member except the author, each in their own locale.

### Phase 3 — Discord channel post
1. Post to `Discord::EventAnnouncement.fleet_targets(fleet)` through `DeliverAnnouncementJob`, with copy in all 7 `discord.yml` files.

### Phase 4 — Schema and CI
1. Regenerate the schema, AsyncAPI and clients, and add oasdiff-ignore lines for the new enum values, generated with the pinned 1.18.1.

## Key files

| File | Role |
|------|------|
| `app/models/notification.rb` | Enum and `TYPES` |
| `app/lib/notifications/in_app/fleet_contract_subscriber.rb` | Subscriber template |
| `app/lib/notification_record_reference.rb` | Record reference for the "open fleet" action |
| `lib/discord/event_announcement.rb` | Discord targets |
| `app/frontend/frontend/pages/settings/notifications.vue` | Preference groups |
| `app/frontend/frontend/composables/useNotificationActions.ts` | `PRIMARY_ACTIONS` |

## Discovery Log

- **2026-10-10** A research pass mapped the pipeline. There is no per-type icon registry, so the icon is a full class passed to `notify!`. The event and contract subscribers pass bare names (`"calendar"`), which looks like a bug, so I won't copy it.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
