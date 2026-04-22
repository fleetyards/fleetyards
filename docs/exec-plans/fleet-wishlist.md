# Exec Plan: Fleet Wishlist

Resolves #1408

## Problem

Fleets have no way to express which ships they need. Members can see what the fleet already owns (via fleet vehicles), but there's no mechanism for fleet leadership to communicate "we need more Hammerheads" or "we're looking for a Reclaimer pilot." Fleet members who want to contribute don't know what gaps to fill.

Individual users already have a personal wishlist (`Vehicle.wanted`), but there's no fleet-level equivalent.

## Current State

- **Fleet vehicles** sync automatically from accepted members' hangars (non-wanted, visible vehicles)
- **Personal wishlist** uses the `wanted` boolean on `Vehicle` — a user-level concept tied to a specific vehicle record
- **Fleet stats controllers** already have placeholder fields: `wishlist_total_money: 0` and `wishlist_total_credits: 0`
- **Privilege system** on fleet resources follows a consistent pattern: `AVAILABLE_PRIVILEGES`, `DEFAULT_PRIVILEGES`, policy checks

## Design Decisions

1. **Model-level, not vehicle-level**: Fleet wishlist items reference a `Model` (ship type), not a `Vehicle` (user-owned instance). The fleet says "we need 2 Hammerheads" — it doesn't care which specific vehicle fills that need.
2. **Quantity + fulfillment tracking**: Each item has a `count` (how many the fleet wants) and the system calculates how many the fleet already has from fleet vehicles. This gives a clear "3 of 5 filled" view.
3. **Privilege-based access**: Uses the existing fleet privilege system. Officers/admins can manage wishlist items; members can view them.
4. **Public visibility**: Follows `public_fleet` flag — if a fleet is public, its wishlist is visible to non-members. This helps with recruitment ("we're looking for capital ship pilots").
5. **No auto-remove on fulfillment**: When enough fleet members own the wished model, the item stays (with "fulfilled" status). Fleet leadership removes items manually. This avoids confusing automatic changes.
6. **Stats integration**: Fill the existing `wishlist_total_money` / `wishlist_total_credits` placeholders in fleet stats.

## Plan

### Phase 1: Database — New `fleet_wishlist_items` Table

**File:** New migration

```ruby
create_table :fleet_wishlist_items, id: :uuid do |t|
  t.references :fleet, type: :uuid, null: false, foreign_key: true
  t.references :model, type: :uuid, null: false, foreign_key: true
  t.integer :count, null: false, default: 1
  t.text :notes
  t.uuid :added_by

  t.timestamps
end

add_index :fleet_wishlist_items, [:fleet_id, :model_id], unique: true
```

Fields:
- `fleet_id` + `model_id` — unique pair (one entry per ship model per fleet)
- `count` — how many the fleet wants (minimum 1)
- `notes` — optional text explaining why the fleet needs this ship
- `added_by` — user_id of the member who added it (for audit trail)

### Phase 2: Model — `FleetWishlistItem`

**File:** `app/models/fleet_wishlist_item.rb`

```ruby
class FleetWishlistItem < ApplicationRecord
  paginates_per 30
  max_paginates_per 240

  belongs_to :fleet, touch: true
  belongs_to :model
  belongs_to :added_by_user, class_name: 'User', foreign_key: :added_by, optional: true

  validates :model_id, uniqueness: { scope: :fleet_id }
  validates :count, numericality: { greater_than: 0 }

  AVAILABLE_PRIVILEGES = [
    'fleet:wishlist:read',
    'fleet:wishlist:create',
    'fleet:wishlist:update',
    'fleet:wishlist:delete',
    'fleet:wishlist:manage'
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ['fleet:wishlist:manage'],
    member: ['fleet:wishlist:read']
  }.freeze

  DEFAULT_SORTING_PARAMS = ['model_name asc']
  ALLOWED_SORTING_PARAMS = [
    'modelName asc', 'modelName desc',
    'count asc', 'count desc',
    'createdAt asc', 'createdAt desc',
    'updatedAt asc', 'updatedAt desc'
  ]

  ransack_alias :search, :model_name_or_model_slug

  def self.ransackable_attributes(auth_object = nil)
    ['count', 'created_at', 'fleet_id', 'id', 'model_id', 'notes', 'updated_at']
  end

  def self.ransackable_associations(auth_object = nil)
    ['fleet', 'model']
  end

  # Number of this model the fleet currently owns (non-loaner)
  def fulfilled_count
    fleet.vehicles.where(model_id: model_id, loaner: false).count
  end

  def fulfilled?
    fulfilled_count >= count
  end
end
```

**File:** `app/models/fleet.rb` — Add association:

```ruby
has_many :fleet_wishlist_items, dependent: :destroy
```

### Phase 3: Policy — Authorization

**File:** `app/policies/fleet_wishlist_item_policy.rb`

Follow the same pattern as `FleetVehiclePolicy`:
- `index?` — requires `fleet:manage`, `fleet:wishlist:manage`, or `fleet:wishlist:read`
- `create?` — requires `fleet:manage`, `fleet:wishlist:manage`, or `fleet:wishlist:create`
- `update?` — requires `fleet:manage`, `fleet:wishlist:manage`, or `fleet:wishlist:update`
- `destroy?` — requires `fleet:manage`, `fleet:wishlist:manage`, or `fleet:wishlist:delete`

**File:** `app/policies/public/fleet_wishlist_item_policy.rb`

- `index?` — allowed if fleet is public (`public_fleet?`)

### Phase 4: Controller — API Endpoints

**File:** `app/controllers/api/v1/fleet_wishlist_items_controller.rb`

Endpoints:
- `GET /api/v1/fleets/:slug/wishlist` — List wishlist items (paginated, filterable via Ransack). Each item includes `fulfilled_count` from fleet vehicles.
- `POST /api/v1/fleets/:slug/wishlist` — Add a model to the wishlist. Params: `model_id`, `count`, `notes`.
- `PUT /api/v1/fleets/:slug/wishlist/:id` — Update count or notes.
- `DELETE /api/v1/fleets/:slug/wishlist/:id` — Remove from wishlist.

Response shape (per item):
```json
{
  "id": "uuid",
  "model": { /* standard model serialization */ },
  "count": 3,
  "fulfilledCount": 1,
  "fulfilled": false,
  "notes": "We need more escort fighters",
  "addedBy": "username",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**File:** `app/controllers/api/v1/public/fleet_wishlist_items_controller.rb`

- `GET /api/v1/public/fleets/:slug/wishlist` — Public read-only access (when `public_fleet` is true). Same shape but without `addedBy`.

### Phase 5: Routes

**File:** `config/routes/api/fleets_routes.rb`

Add nested under fleet:
```ruby
resources :wishlist,
  controller: 'fleet_wishlist_items',
  only: [:index, :create, :update, :destroy]
```

Add under public fleet:
```ruby
resources :wishlist,
  controller: 'public/fleet_wishlist_items',
  only: [:index]
```

### Phase 6: Views (Jbuilder)

**File:** `app/views/api/v1/fleet_wishlist_items/index.jbuilder`

Standard paginated list response following existing fleet view patterns.

**File:** `app/views/api/v1/fleet_wishlist_items/_base.jbuilder`

Item serialization including model association, counts, and fulfillment status.

### Phase 7: Stats Integration

**File:** `app/controllers/api/v1/fleet_stats_controller.rb`

Update `fleet_metrics` method to calculate actual wishlist totals:
```ruby
wishlist_items = fleet.fleet_wishlist_items.includes(:model)
wishlist_total_money = wishlist_items.sum { |item| (item.model.price || 0) * item.count }
wishlist_total_credits = wishlist_items.sum { |item| (item.model.pledge_price || 0) * item.count }
```

Replace the hardcoded `0` values for `wishlist_total_money` and `wishlist_total_credits`.

Do the same in `app/controllers/api/v1/public/fleet_stats_controller.rb`.

### Phase 8: RSpec Tests

**Files:**
- `spec/requests/api/v1/fleet_wishlist_items_spec.rb` — CRUD operations, authorization, pagination, filtering
- `spec/requests/api/v1/public/fleet_wishlist_items_spec.rb` — Public read-only access
- `spec/models/fleet_wishlist_item_spec.rb` — Validations, fulfilled_count logic
- `spec/policies/fleet_wishlist_item_policy_spec.rb` — Privilege checks

Use rswag swagger_helper for API spec generation.

### Phase 9: OpenAPI Schema + Orval

1. Run `./bin/generate-schema` to generate OpenAPI spec from rswag tests
2. Run Orval to generate frontend TypeScript client and types

### Phase 10: Frontend — Wishlist Page

**File:** `app/frontend/frontend/pages/fleets/[slug]/wishlist.vue`

New fleet sub-page (add to fleet navigation alongside Ships, Stats, Members, Settings):
- Conditional render: `FleetWishlist` (member) vs `PublicFleetWishlist` (public)
- Follows the same pattern as `ships.vue`

**File:** `app/frontend/frontend/components/Fleets/FleetWishlist/index.vue`

Member-facing wishlist component:
- Grid/table view of wishlist items showing ship image, name, wanted count, fulfilled count, progress indicator
- "Add Ship" button (for users with create privilege) — opens a model search/picker modal
- Inline edit for count and notes (for users with update privilege)
- Delete button (for users with delete privilege)
- Filtering by classification, manufacturer, size (reuse existing filter patterns)
- Sort by name, count, fulfillment, date added

**File:** `app/frontend/frontend/components/Fleets/PublicFleetWishlist/index.vue`

Public-facing wishlist (read-only):
- Same layout without action buttons
- Useful for recruitment — shows what the fleet is looking for

### Phase 11: Frontend — Navigation Integration

**File:** `app/frontend/frontend/pages/fleets/[slug].vue` (or fleet nav component)

Add "Wishlist" tab to fleet navigation, between Ships and Stats. Only show if user has `fleet:wishlist:read` privilege (or fleet is public).

### Phase 12: Frontend — Stats Integration

**File:** `app/frontend/frontend/components/Fleets/FleetStats/index.vue`

Display the now-populated `wishlistTotalMoney` and `wishlistTotalCredits` values in the stats metrics section. Add a link to the wishlist page.

**File:** `app/frontend/frontend/components/Fleets/PublicFleetStats/index.vue`

Same for public stats.

### Phase 13: ActionCable Broadcasting (Optional Enhancement)

**File:** New channel `FleetWishlistChannel`

Broadcast wishlist changes to fleet members in real-time, following the pattern of `FleetVehiclesChannel`. This keeps the wishlist page live-updating when officers add/remove items.

### Phase 14: Translations

**Files:** `app/frontend/translations/en.json` (and other locale files)

Add translations for:
- Page title, empty state, action buttons
- Fulfillment labels ("3 of 5", "Fulfilled", "Needed")
- Notification text (if adding notifications)

## File Change Summary

| File | Change |
|------|--------|
| New migration | Create `fleet_wishlist_items` table |
| `app/models/fleet_wishlist_item.rb` | New model with privileges, validations, fulfillment logic |
| `app/models/fleet.rb` | Add `has_many :fleet_wishlist_items` |
| `app/policies/fleet_wishlist_item_policy.rb` | Authorization policy |
| `app/policies/public/fleet_wishlist_item_policy.rb` | Public authorization policy |
| `app/controllers/api/v1/fleet_wishlist_items_controller.rb` | CRUD API controller |
| `app/controllers/api/v1/public/fleet_wishlist_items_controller.rb` | Public read-only controller |
| `config/routes/api/fleets_routes.rb` | Add wishlist routes |
| `app/views/api/v1/fleet_wishlist_items/` | Jbuilder views |
| `app/controllers/api/v1/fleet_stats_controller.rb` | Populate wishlist_total_money/credits |
| `app/controllers/api/v1/public/fleet_stats_controller.rb` | Same for public stats |
| `spec/requests/api/v1/fleet_wishlist_items_spec.rb` | API tests |
| `spec/requests/api/v1/public/fleet_wishlist_items_spec.rb` | Public API tests |
| `spec/models/fleet_wishlist_item_spec.rb` | Model tests |
| `app/frontend/frontend/pages/fleets/[slug]/wishlist.vue` | New wishlist page |
| `app/frontend/frontend/components/Fleets/FleetWishlist/index.vue` | Member wishlist component |
| `app/frontend/frontend/components/Fleets/PublicFleetWishlist/index.vue` | Public wishlist component |
| `app/frontend/frontend/pages/fleets/[slug].vue` | Add wishlist to fleet nav |
| `app/frontend/frontend/components/Fleets/FleetStats/index.vue` | Show wishlist totals |
| `app/frontend/frontend/components/Fleets/PublicFleetStats/index.vue` | Show wishlist totals (public) |
| `app/frontend/translations/en.json` | Add translations |

## Implementation Order

Phases 1-6 (backend) can be done first as a complete backend PR. Phases 7-8 (stats + tests) build on that. Phases 9-14 (frontend) can be a second PR after the API is stable. Phase 13 (ActionCable) is optional and can be deferred.

## Open Questions

1. **Priority field?** Should wishlist items have a priority (high/medium/low) for sorting? Kept simple for now — can add later.
2. **Notifications?** Should members get notified when a new wishlist item is added? ("The fleet is looking for Hammerhead pilots!") Could be a nice enhancement but adds complexity.
3. **Member self-assignment?** Should members be able to signal "I'm working on getting this ship"? Would add a join table but provides useful coordination. Deferred for now.
