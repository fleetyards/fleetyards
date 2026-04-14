# Notification Center Backend

Currently all notifications in FleetYards are ephemeral — WebSocket broadcasts that appear as toast messages and disappear after a few seconds. There is no way for users to review past notifications. This plan adds a persistent Notification model, API endpoints, notification preferences with channel routing, and updates existing jobs to write notification records, enabling a future frontend notification center panel.

Resolves the notification center backend feature.

## Current Notification Landscape

### Mailers

| Mailer | Action | Trigger | Stream |
|--------|--------|---------|--------|
| `VehicleMailer` | `on_sale(vehicle)` | `ModelOnSaleJob` | broadcast |
| `ModelMailer` | `notify_new(to, model)` | Not currently called | broadcast |
| `FleetMembershipMailer` | `new_invite(to, username, fleet)` | `FleetMembership` invite callback | transactional |
| `FleetMembershipMailer` | `member_requested(to, member_username, fleet)` | `FleetMembership` notify_fleet_admins | transactional |
| `FleetMembershipMailer` | `member_accepted(to, member_username, fleet)` | `FleetMembership` notify_fleet_admins | transactional |
| `FleetMembershipMailer` | `fleet_accepted(to, username, fleet)` | `FleetMembership` accept callback | transactional |
| `UserMailer` | `username_changed(to, username)` | `User` after_update | transactional |
| `TwoFactorMailer` | `enabled(to, username)` | `User` 2FA toggle | transactional |
| `TwoFactorMailer` | `disabled(to, username)` | `User` 2FA toggle | transactional |
| `AdminMailer` | `weekly(stats)` | `AdminJob` (cron) | transactional |
| `AdminMailer` | `notify_block(url)` | `RsiRequestLog` | transactional |
| `AdminMailer` | `notify_unblock(url)` | `RsiRequestLog` | transactional |

### ActionCable Channels (user-specific)

| Channel | Trigger | Purpose |
|---------|---------|---------|
| `UserNotificationsChannel` | `Notification.notify!` | Notification center updates |
| `HangarCreateChannel` | `Vehicle#broadcast_create` | Hangar addition toast |
| `WishlistCreateChannel` | `Vehicle#broadcast_create` | Wishlist addition toast |
| `HangarDestroyChannel` | `Vehicle#broadcast_destroy` | Hangar removal toast |
| `WishlistDestroyChannel` | `Vehicle#broadcast_destroy` | Wishlist removal toast |
| `HangarChannel` | `Vehicle#broadcast_update`, `HangarGroup#broadcast_update` | Hangar live updates |
| `WishlistChannel` | `Vehicle#broadcast_update` | Wishlist live updates |
| `HangarSyncChannel` | `HangarSync#run_with_import` | Sync progress/result |
| `OnSaleHangarChannel` | `ModelOnSaleJob` | Sale notification toast |
| `FleetMembersChannel` | `FleetMembership` callbacks | Fleet member changes |
| `FleetVehiclesChannel` | `FleetMembership` callbacks | Fleet vehicle changes |
| `ImportsChannel` | `Import` state changes | Admin import progress |

### ActionCable Channels (global broadcast)

| Channel | Trigger | Purpose |
|---------|---------|---------|
| `OnSaleChannel` | `Model#send_on_sale_notification` | Global sale broadcast |
| `ModelsChannel` | `Model#broadcast_update` | Model data updates |
| `AppVersionChannel` | `AppVersionJob` (cron) | App version broadcast |
| `NotificationsChannel` | Not currently used | Reserved |

### Discord Webhooks

| Webhook | Trigger | Endpoint |
|---------|---------|----------|
| `Discord::ShipOnSale` | `ModelOnSaleJob` | discord_updates_endpoint |
| `Discord::NewShip` | `NewModelJob` | discord_updates_endpoint |
| `Discord::RsiNews` | `StarCitizenUpdate#notify` | discord_sc_updates_endpoint |
| `Discord::YoutubeVideo` | `YoutubeUpdate#notify` | discord_sc_updates_endpoint |

### Existing User-Level Settings

| Setting | Model | Default | Purpose |
|---------|-------|---------|---------|
| `sale_notify` | `User` | `false` | Opt-in to sale notifications |
| `notify` | `Vehicle` | `true` | Per-vehicle notification toggle |
| `sale_notify` | `Vehicle` | `false` | Per-vehicle sale notification toggle |

## Notification Types

| Type | Trigger | Channels | Mailer | Record | Retention | Default |
|------|---------|----------|--------|--------|-----------|---------|
| `hangar_create` | `Vehicle#broadcast_create` (owned) | app | — | — | 7 days | app: true |
| `hangar_destroy` | `Vehicle#broadcast_destroy` (owned) | app | — | — | 7 days | app: true |
| `wishlist_create` | `Vehicle#broadcast_create` (wanted) | app | — | — | 7 days | app: true |
| `wishlist_destroy` | `Vehicle#broadcast_destroy` (wanted) | app | — | — | 7 days | app: true |
| `model_on_sale` | `ModelOnSaleJob` | app, mail | `VehicleMailer.on_sale` | Vehicle | 30 days | all off (opt-in) |
| `on_sale` | reserved (general sale) | app, mail | `VehicleMailer.on_sale` | Vehicle | 30 days | all off (opt-in) |
| `new_model` | `NewModelJob` | app, mail | `ModelMailer.notify_new` | Model | 30 days | app: true |
| `hangar_sync_finished` | `HangarSync#run_with_import` | app | — | — | 90 days | app: true |
| `hangar_sync_failed` | `HangarSync#run_with_import` | app | — | — | 90 days | app: true |
| `fleet_invite` | `FleetMembership` invite event | app, mail | `FleetMembershipMailer.new_invite` | FleetMembership | 30 days | app: true, mail: true |
| `fleet_member_requested` | `FleetMembership` request event | app, mail | `FleetMembershipMailer.member_requested` | FleetMembership | 30 days | app: true, mail: true |
| `fleet_member_accepted` | `FleetMembership` accept_invitation event | app, mail | `FleetMembershipMailer.member_accepted` | FleetMembership | 30 days | app: true, mail: true |
| `fleet_request_accepted` | `FleetMembership` accept_request event | app, mail | `FleetMembershipMailer.fleet_accepted` | FleetMembership | 30 days | app: true, mail: true |

### Fleet notification recipients

- `fleet_invite` → the invited user (1 notification)
- `fleet_request_accepted` → the user whose request was accepted (1 notification)
- `fleet_member_requested` → each fleet admin (N notifications, one per admin)
- `fleet_member_accepted` → each fleet admin (N notifications, one per admin)

## Decisions

### D1 — Centralized type configuration

All notification type metadata (retention, supported channels, mailer, preference defaults) lives in `Notification::TYPES`. This is the single source of truth — `NotificationPreference` derives its defaults from it.

### D2 — Notifications table is the audit log

`Notification.notify!` always creates a row. If the user has `app: false`, the notification is created with `read_at` set (appears as read, no WebSocket broadcast). This keeps the notification center as a complete history.

### D3 — Polymorphic record association

Notifications can reference the triggering record (e.g., a Vehicle for `model_on_sale`, a FleetMembership for fleet notifications). This lets mailers and future features access the original context without encoding it all into the notification fields.

### D4 — Preference defaults are type-aware

Most types default to `app: true, mail: false, push: false`. Types that were previously opt-in (like `model_on_sale` via `User.sale_notify`) default to all-off, matching existing behavior. Fleet notifications default to `app: true, mail: true` since they currently always send email.

### D5 — Backward compatibility with sale_notify

During transition, `User.sale_notify` changes sync to `notification_preferences` via `after_update` callback. A maintenance task backfills existing users. This will be removed once the frontend uses notification preferences directly.

### D6 — Mailer lambdas derive context from notification + record

Each mailer lambda receives the notification and pulls what it needs from `notification.user` and `notification.record`. For fleet admin notifications, `notify!` is called once per admin (the admin is the `user`), and the membership (which has the requesting/joining user + fleet) is the `record`.

### D7 — Out of scope mailers

Admin mailers (`AdminMailer`) and security mailers (`UserMailer.username_changed`, `TwoFactorMailer`) are not managed through the notification preference system — they are system/security emails that cannot be disabled.

---

## Progress

- [x] Phase 1 — Database and Model
- [x] Phase 2 — Policy, Controller, Routes
- [x] Phase 3 — Views and API Schema
- [x] Phase 4 — Persist notifications in existing jobs
- [x] Phase 5 — Cleanup job
- [x] Phase 6 — RSpec request specs
- [x] Phase 7 — Linting and schema generation
- [x] Phase 8 — Notification preferences table and model
- [x] Phase 9 — Notification preferences API endpoints
- [x] Phase 10 — Backfill maintenance task and sale_notify sync
- [ ] Phase 11 — Centralized type config with channel routing
- [ ] Phase 12 — Polymorphic record association
- [ ] Phase 13 — Add fleet and new_model notification types
- [ ] Phase 14 — Update all callers to use generic notify! with record
- [ ] Phase 15 — Update backfill task for new types
- [ ] Phase 16 — Specs for notification preferences
- [ ] Phase 17 — Linting and schema regeneration

---

## Phase 1–7: Notification Center Backend (DONE)

See git history for implementation details. Covers: notifications table, model, policy, controller, routes, views, API schema, persisting in existing jobs, cleanup job, request specs, linting.

## Phase 8: Notification Preferences Table and Model (DONE)

### Migration

**Created** `db/migrate/20260414153819_create_notification_preferences.rb`

```ruby
create_table :notification_preferences, id: :uuid do |t|
  t.references :user, type: :uuid, null: false, foreign_key: true, index: false
  t.string :notification_type, null: false
  t.boolean :app, null: false, default: true
  t.boolean :mail, null: false, default: false
  t.boolean :push, null: false, default: false
  t.timestamps
end

add_index :notification_preferences, [:user_id, :notification_type], unique: true
```

### Model

**Created** `app/models/notification_preference.rb`

- `belongs_to :user`
- `enum :notification_type` (shared with Notification)
- `validates :notification_type, presence: true, uniqueness: { scope: :user_id }`
- `DEFAULTS` and `TYPE_DEFAULTS` for per-type default preferences
- `MAIL_ENABLED_TYPES` for frontend to know which types support mail
- `.for(user:, type:)` — finds or returns unsaved default
- `.defaults_for(type)` — returns default preferences for a type
- `.mail_available?(type)` — checks if mail channel is supported

### User association

**Modified** `app/models/user.rb`

- Added `has_many :notification_preferences, dependent: :delete_all`
- Added `after_create :create_default_notification_preferences` — seeds all types on signup
- Added `after_update :sync_sale_notify_preference` — syncs `sale_notify` changes to preference

## Phase 9: Notification Preferences API Endpoints (DONE)

### Controller

**Created** `app/controllers/api/v1/notification_preferences_controller.rb`

- `index` — returns all types with current preferences (fills defaults for unconfigured)
- `update` — find_or_initialize_by notification_type, update with permitted params (app, mail, push)

### Policy

**Created** `app/policies/notification_preference_policy.rb`

### Routes

**Created** `config/routes/api/notification_preferences_routes.rb`

- `GET /api/v1/notification-preferences`
- `PUT /api/v1/notification-preferences/:notification_type`

### Views

**Created** in `app/views/api/v1/notification_preferences/`:
- `_base.jbuilder` — notification_type, app, mail, push, mail_available
- `_notification_preference.jbuilder` — partial wrapper
- `index.jbuilder` — array
- `show.jbuilder` — single

### API Schema

**Created** `app/api_components/v1/schemas/notification_preference.rb`

## Phase 10: Backfill and sale_notify sync (DONE)

### Maintenance task

**Created** `app/tasks/maintenance/backfill_notification_preferences_task.rb`

- Iterates all confirmed users
- Creates `model_on_sale` preference: `app: sale_notify, mail: sale_notify`
- Users with `sale_notify: false` get `app: false, mail: false`

## Phase 11: Centralized Type Config with Channel Routing

Replace the scattered `RETENTION` hash, `MAIL_ENABLED_TYPES`, and `TYPE_DEFAULTS` with a single `Notification::TYPES` config.

### Modify `app/models/notification.rb`

Replace `RETENTION` with `TYPES`:

```ruby
TYPES = {
  hangar_create: {
    retention: 7.days,
    channels: %i[app]
  },
  hangar_destroy: {
    retention: 7.days,
    channels: %i[app]
  },
  wishlist_create: {
    retention: 7.days,
    channels: %i[app]
  },
  wishlist_destroy: {
    retention: 7.days,
    channels: %i[app]
  },
  model_on_sale: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) { VehicleMailer.on_sale(notification.record).deliver_later },
    preference_defaults: { app: false, mail: false, push: false }
  },
  on_sale: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) { VehicleMailer.on_sale(notification.record).deliver_later },
    preference_defaults: { app: false, mail: false, push: false }
  },
  new_model: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) { ModelMailer.notify_new(notification.user.email, notification.record).deliver_later }
  },
  hangar_sync_finished: {
    retention: 90.days,
    channels: %i[app]
  },
  hangar_sync_failed: {
    retention: 90.days,
    channels: %i[app]
  },
  fleet_invite: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) {
      membership = notification.record
      FleetMembershipMailer.new_invite(notification.user.email, notification.user.username, membership.fleet).deliver_later
    },
    preference_defaults: { app: true, mail: true, push: false }
  },
  fleet_member_requested: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) {
      membership = notification.record
      FleetMembershipMailer.member_requested(notification.user.email, membership.user.username, membership.fleet).deliver_later
    },
    preference_defaults: { app: true, mail: true, push: false }
  },
  fleet_member_accepted: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) {
      membership = notification.record
      FleetMembershipMailer.member_accepted(notification.user.email, membership.user.username, membership.fleet).deliver_later
    },
    preference_defaults: { app: true, mail: true, push: false }
  },
  fleet_request_accepted: {
    retention: 30.days,
    channels: %i[app mail],
    mailer: ->(notification) {
      membership = notification.record
      FleetMembershipMailer.fleet_accepted(notification.user.email, notification.user.username, membership.fleet).deliver_later
    },
    preference_defaults: { app: true, mail: true, push: false }
  }
}.freeze
```

Add class methods:
- `type_config(type)` — fetches config from TYPES
- `retention_for(type)` — from config
- `channels_for(type)` — from config
- `mailer_for(type)` — from config
- `preference_defaults_for(type)` — from config with fallback

Update `notify!(user:, type:, title:, body: nil, link: nil, icon: nil, record: nil)`:
- Always creates notification (with `record:`)
- Checks preference, sets `read_at` if `app: false`
- Broadcasts WebSocket if `app: true`
- Calls mailer if `mail: true` and mailer defined for type

### Modify `app/models/notification_preference.rb`

Remove `DEFAULTS`, `TYPE_DEFAULTS`, `MAIL_ENABLED_TYPES`. Derive from `Notification::TYPES`:

```ruby
def self.defaults_for(type)
  Notification.preference_defaults_for(type)
end

def self.mail_available?(type)
  Notification.channels_for(type).include?(:mail)
end
```

## Phase 12: Polymorphic Record Association

### Migration

**Create** `db/migrate/YYYYMMDDHHMMSS_add_record_to_notifications.rb`

```ruby
add_reference :notifications, :record, polymorphic: true, type: :uuid, index: true
```

### Model

**Modify** `app/models/notification.rb`

Add: `belongs_to :record, polymorphic: true, optional: true`

## Phase 13: Add Fleet and New Model Notification Types

### Modify `app/models/notification.rb`

Add new enum values:

```ruby
enum :notification_type, {
  # ... existing types ...
  fleet_invite: "fleet_invite",
  fleet_member_requested: "fleet_member_requested",
  fleet_member_accepted: "fleet_member_accepted",
  fleet_request_accepted: "fleet_request_accepted"
}
```

Add corresponding entries in `TYPES` (see Phase 11).

### Add i18n translations

**Modify** `config/locales/en/notifications.yml` — add fleet and new_model titles/bodies.

## Phase 14: Update All Callers to Use Generic notify! with Record

### Modify `app/jobs/notifications/model_on_sale_job.rb`

Remove manual preference check and mailer call. Just pass `record: vehicle`:

```ruby
Vehicle.where(...).find_each do |vehicle|
  OnSaleHangarChannel.broadcast_to(vehicle.user, vehicle.to_json)
  Notification.notify!(
    user: vehicle.user,
    type: :model_on_sale,
    title: ...,
    record: vehicle
  )
end
```

### Modify `app/jobs/notifications/new_model_job.rb`

After Discord webhook, create notification for subscribed users:

```ruby
Notification.notify!(
  user: user,
  type: :new_model,
  title: ...,
  record: model
)
```

Note: `new_model` currently only fires Discord. Need to decide who receives in-app notifications — possibly all confirmed users, or users who have the preference enabled. For now, the type is wired but the job only creates notifications when called.

### Modify `app/models/fleet_membership.rb`

Replace direct mailer calls with `Notification.notify!`:

**`notify_invited_user`** (line 232):
```ruby
def notify_invited_user
  return unless invited?
  return if user.email.blank?

  Notification.notify!(
    user: user,
    type: :fleet_invite,
    title: I18n.t("notifications.fleet_invite.title", fleet: fleet.name),
    link: "/fleets",
    record: self
  )
end
```

**`notify_fleet_admins`** (line 247) — one notification per admin:
```ruby
def notify_fleet_admins
  return unless requested? || accepted?

  admin_users = fleet.fleet_memberships.accepted.includes(:fleet_role, :user).select { |m|
    m.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:update"])
  }.filter_map { |m| m.user if m.user.email.present? }

  type = requested? ? :fleet_member_requested : :fleet_member_accepted

  admin_users.each do |admin_user|
    Notification.notify!(
      user: admin_user,
      type: type,
      title: I18n.t("notifications.#{type}.title", username: user.username, fleet: fleet.name),
      link: "/fleets/#{fleet.slug}/members",
      record: self
    )
  end
end
```

**`notify_new_member`** (line 271):
```ruby
def notify_new_member
  return unless accepted?
  return if user.email.blank?

  Notification.notify!(
    user: user,
    type: :fleet_request_accepted,
    title: I18n.t("notifications.fleet_request_accepted.title", fleet: fleet.name),
    link: "/fleets",
    record: self
  )
end
```

### No changes to Vehicle callbacks or HangarSync

These types only have `app` channel — `notify!` already handles them correctly. No `record` needed for these types currently.

## Phase 15: Update Backfill Task for New Types

### Modify `app/tasks/maintenance/backfill_notification_preferences_task.rb`

Add fleet notification types with `app: true, mail: true` defaults for all confirmed users (matching current always-send-email behavior).

### Modify `app/models/user.rb` `create_default_notification_preferences`

Already iterates all `notification_types` — new types are automatically included on signup.

## Phase 16: Specs for Notification Preferences

**Create** in `spec/requests/api/v1/notification_preferences/`:
- `index_spec.rb` — returns all types with defaults, with custom preferences
- `update_spec.rb` — updates preference, creates if not exists

**Update** `spec/factories/notification_preferences.rb` — already created with traits

## Phase 17: Linting and Schema Regeneration

1. `bundle exec standardrb --fix` on all new/modified `.rb` files
2. `./bin/generate-schema` to regenerate OpenAPI schema
3. Run all notification specs

## Key Files

| File | Role |
|------|------|
| `app/models/notification.rb` | Core model with TYPES config and notify! |
| `app/models/notification_preference.rb` | Per-user per-type channel preferences |
| `app/models/user.rb` | Associations, signup seeding, sale_notify sync |
| `app/models/fleet_membership.rb` | Fleet notification triggers |
| `app/controllers/api/v1/notifications_controller.rb` | Notification CRUD API |
| `app/controllers/api/v1/notification_preferences_controller.rb` | Preferences API |
| `app/policies/notification_policy.rb` | Notification authorization |
| `app/policies/notification_preference_policy.rb` | Preferences authorization |
| `app/jobs/notifications/model_on_sale_job.rb` | Sale notification job |
| `app/jobs/notifications/new_model_job.rb` | New model notification job |
| `app/lib/hangar_sync.rb` | Hangar sync notifications |
| `app/models/vehicle.rb` | Hangar/wishlist notifications |
| `app/mailers/vehicle_mailer.rb` | Sale email |
| `app/mailers/model_mailer.rb` | New model email |
| `app/mailers/fleet_membership_mailer.rb` | Fleet emails (invite, request, accept) |
| `app/tasks/maintenance/backfill_notification_preferences_task.rb` | Backfill task |
| `config/routes/api/notification_preferences_routes.rb` | Preferences routes |
| `config/locales/en/notifications.yml` | Notification i18n strings |

## Not in Scope (deferred)

- **Push notifications** — `push` column is wired but no delivery mechanism yet
- **Frontend notification center UI** — separate feature
- **Removing `User.sale_notify`** — kept for backward compatibility until frontend uses preferences API
- **Per-vehicle `notify` / `sale_notify` migration** — these are per-vehicle toggles, different from per-type preferences
- **Admin mailers** — `AdminMailer` (weekly stats, block/unblock) are admin-only
- **Security mailers** — `UserMailer.username_changed`, `TwoFactorMailer` are security emails that must always send

## Discovery Log

- **2026-04-13** Initial plan and Phase 1–7 implementation
- **2026-04-14** Added notification preferences (Phase 8–10), centralized type config design (Phase 11–13), added fleet and new_model notification types (Phase 13–15)
