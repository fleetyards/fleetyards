# Notification Center Backend

Currently all notifications in FleetYards are ephemeral — WebSocket broadcasts that appear as toast messages and disappear after a few seconds. There is no way for users to review past notifications. This plan adds a persistent Notification model, API endpoints, and updates existing jobs to write notification records, enabling a future frontend notification center panel.

## Notification Types and Retention

| Type | Trigger | Retention |
|------|---------|-----------|
| `hangar_create` | Vehicle added to hangar | 7 days |
| `hangar_destroy` | Vehicle removed from hangar | 7 days |
| `wishlist_create` | Vehicle added to wishlist | 7 days |
| `wishlist_destroy` | Vehicle removed from wishlist | 7 days |
| `model_on_sale` | Ship goes on sale (user's hangar) | 30 days |
| `on_sale` | Ship goes on sale (general) | 30 days |
| `new_model` | New ship model announced | 30 days |
| `hangar_sync_finished` | RSI hangar sync completed | 90 days |
| `hangar_sync_failed` | RSI hangar sync failed | 90 days |

## Phase 1: Database and Model

### Migration

**Create** `db/migrate/YYYYMMDDHHMMSS_create_notifications.rb`

```ruby
create_table :notifications, id: :uuid do |t|
  t.references :user, type: :uuid, null: false, foreign_key: true, index: false
  t.string :notification_type, null: false
  t.string :title, null: false
  t.text :body
  t.string :link
  t.string :icon
  t.datetime :read_at
  t.datetime :expires_at, null: false
  t.timestamps
end

add_index :notifications, [:user_id, :created_at], order: {created_at: :desc}
add_index :notifications, [:user_id, :read_at]
add_index :notifications, :expires_at
add_index :notifications, :notification_type
```

### Model

**Create** `app/models/notification.rb`

- `belongs_to :user`
- `enum :notification_type` with string-backed values (all 9 types above)
- `RETENTION` constant mapping type groups to durations (7d / 30d / 90d)
- `retention_for(type)` class method
- `before_validation :set_expires_at, on: :create` — sets `expires_at` from type retention
- Scopes: `unread`, `read`, `expired`, `active`
- `paginates_per 25`
- `ransackable_attributes`: `notification_type`, `read_at`, `created_at`
- Instance methods: `read?`, `mark_as_read!`
- Class method: `notify!(user:, type:, title:, body: nil, link: nil, icon: nil)` — creates record + broadcasts via `UserNotificationsChannel`

### User association

**Modify** `app/models/user.rb` (~line 113)

Add: `has_many :notifications, dependent: :delete_all`

### Factory

**Create** `spec/factories/notifications.rb`

Traits: `:read`, `:unread` (default), `:expired`, `:hangar_sync`

## Phase 2: Policy, Controller, Routes

### Policy

**Create** `app/policies/notification_policy.rb`

- `show?` / `destroy?` / `update?` — `user.present?`
- `read_all?` / `destroy_all?` — `user.present?`
- `relation_scope` — `relation.where(user_id: user.id)`

Pattern: follows `app/policies/hangar_policy.rb`

### Controller

**Create** `app/controllers/api/v1/notifications_controller.rb`

Actions:
- `index` — paginated list, filtered by `authorized_scope`, only active (non-expired), newest first. Ransack filtering by type and read status.
- `read` (member PUT) — marks single notification as read
- `read_all` (collection PUT) — marks all user's unread notifications as read
- `destroy` (member DELETE) — deletes single notification
- `destroy_all` (collection DELETE) — deletes all user's notifications

Auth: session + Doorkeeper OAuth scopes `notifications`, `notifications:read`, `notifications:write`

Pattern: follows `app/controllers/api/v1/fleet_members_controller.rb`

### Routes

**Create** `config/routes/api/notifications_routes.rb`

```ruby
resources :notifications, only: %i[index destroy] do
  member do
    put :read
  end
  collection do
    put "read-all", to: "notifications#read_all"
    delete "destroy-all", to: "notifications#destroy_all"
  end
end
```

**Modify** `config/routes/api/v1_routes.rb` — add `draw "api/notifications_routes"` after existing draws (~line 40)

## Phase 3: Views and API Schema

### Jbuilder views

**Create** in `app/views/api/v1/notifications/`:

- `_base.jbuilder` — id, notification_type, title, body, link, icon, read (boolean), read_at, expires_at, dates partial
- `_notification.jbuilder` — cache wrapper
- `index.jbuilder` — items array + meta partial
- `read.jbuilder` — single notification partial
- `destroy.jbuilder` — single notification partial

Pattern: follows `app/views/api/v1/vehicles/`

### OpenAPI schema components

**Create** `app/api_components/shared/v1/schemas/enums/notification_type_enum.rb`
- Enum from `Notification.notification_types.keys`
- Pattern: follows `app/api_components/shared/v1/schemas/enums/bought_via_enum.rb`

**Create** `app/api_components/v1/schemas/notification.rb`
- Properties: id, notificationType (ref to enum), title, body, link, icon, read, readAt, expiresAt, createdAt, updatedAt
- Pattern: follows `app/api_components/v1/schemas/image.rb`

**Create** `app/api_components/v1/schemas/notifications.rb`
- Inherits from `Shared::V1::Schemas::BaseList`, adds items array
- Pattern: follows `app/api_components/v1/schemas/images.rb`

## Phase 4: Persist notifications in existing jobs

**Modify** `app/jobs/notifications/model_on_sale_job.rb`
- After `OnSaleHangarChannel.broadcast_to`, call `Notification.notify!` with type `:model_on_sale`

**Modify** `app/models/vehicle.rb` (`broadcast_create` ~line 245, `broadcast_destroy` ~line 255)
- After each channel broadcast, call `Notification.notify!` with appropriate type

**Modify** `app/lib/hangar_sync.rb` (~lines 57 and 64)
- After each `HangarSyncChannel.broadcast_to`, call `Notification.notify!` with `:hangar_sync_finished` or `:hangar_sync_failed`

## Phase 5: Cleanup job

**Create** `app/jobs/cleanup/notifications_job.rb`
- `Notification.expired.in_batches(of: 1000).delete_all`
- Pattern: follows `app/jobs/cleanup/fleet_invite_url_job.rb`

**Modify** `config/sidekiq_schedule.yml` — add:
```yaml
cleanup_notifications_job:
  cron: '0 3 */1 * *'  # Daily at 3:00
  class: 'Cleanup::NotificationsJob'
  queue: 'cleanup'
```

## Phase 6: RSpec request specs

**Create** in `spec/requests/api/v1/notifications/`:
- `index_spec.rb` — test pagination, filtering, auth, scoping
- `read_spec.rb` — test marking as read
- `read_all_spec.rb` — test marking all as read
- `destroy_spec.rb` — test deletion
- `destroy_all_spec.rb` — test bulk deletion

All specs use rswag format with `swagger_doc: "v1/schema.yaml"`, tag `"Notifications"`.
Pattern: follows `spec/requests/api/v1/hangar/show_spec.rb`

## Phase 7: Linting and schema generation

1. `bundle exec standardrb --fix` on all new/modified `.rb` files
2. `./bin/generate-schema` to regenerate OpenAPI schema
3. `bundle exec rspec spec/requests/api/v1/notifications/` to verify

## Files summary

### New files
- `db/migrate/YYYYMMDDHHMMSS_create_notifications.rb`
- `app/models/notification.rb`
- `app/policies/notification_policy.rb`
- `app/controllers/api/v1/notifications_controller.rb`
- `config/routes/api/notifications_routes.rb`
- `app/views/api/v1/notifications/_base.jbuilder`
- `app/views/api/v1/notifications/_notification.jbuilder`
- `app/views/api/v1/notifications/index.jbuilder`
- `app/views/api/v1/notifications/read.jbuilder`
- `app/views/api/v1/notifications/destroy.jbuilder`
- `app/api_components/shared/v1/schemas/enums/notification_type_enum.rb`
- `app/api_components/v1/schemas/notification.rb`
- `app/api_components/v1/schemas/notifications.rb`
- `app/jobs/cleanup/notifications_job.rb`
- `spec/factories/notifications.rb`
- `spec/requests/api/v1/notifications/index_spec.rb`
- `spec/requests/api/v1/notifications/read_spec.rb`
- `spec/requests/api/v1/notifications/read_all_spec.rb`
- `spec/requests/api/v1/notifications/destroy_spec.rb`
- `spec/requests/api/v1/notifications/destroy_all_spec.rb`

### Modified files
- `app/models/user.rb` — add `has_many :notifications`
- `config/routes/api/v1_routes.rb` — draw notifications routes
- `config/sidekiq_schedule.yml` — add cleanup job schedule
- `app/jobs/notifications/model_on_sale_job.rb` — persist notification
- `app/models/vehicle.rb` — persist notification on create/destroy broadcasts
- `app/lib/hangar_sync.rb` — persist notification on sync finish/fail
