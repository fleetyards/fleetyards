# Ship Inventories

## Context

Hangar inventories (#4340) give a user named buckets for commodities, components and
gear. Fleet logistics gives an org the same thing. Neither answers the question people
actually have: *the cargo is in the Ironclad — where is the rest of my stuff?*

A ship's cargo hold is the same bucket with a different holder, so this plan hangs
inventories off vehicles rather than introducing a third subsystem. It also drops the
create-an-inventory step: a ship inventory provisions itself the first time something is
deposited into it, named after the ship.

Slice 2 of the inventory work. Slice 1 is the unified table described below; slice 3 is
migrating fleet inventories onto it, which is what unlocks a combined
hangar + ships + fleets search.

## Prerequisite — the unified table (slice 1, done)

Ship inventories hang off `inventories` / `inventory_items` with a polymorphic holder.
That rework landed inside \#4340 rather than after it: its two migrations had never run in
production, so reshaping them cost a migration rewrite rather than a data migration plus
`versions.item_type` and `active_storage_attachments.record_type` rewrites.

```ruby
create_table :inventories, id: :uuid do |t|
  t.references :holder, type: :uuid, polymorphic: true, null: false, index: false
  t.string :name, null: false
  t.string :slug, null: false
  t.text :description
  t.string :location
  t.timestamps
end
```

Slice 1 shipped without `vehicle_id` — the column arrives with this slice, together with
the partial indexes that depend on it, so \#4340 carries nothing it does not use.

`holder` is *who owns it* — `User` now, `Fleet` in slice 3. `vehicle_id` is *where it is*.
Keeping those separate is what lets slice 3 express "org cargo aboard a member's Hull C"
(`holder: Fleet, vehicle: that ship`), which a `holder: Vehicle` design cannot say.

Fleet-only columns (`visibility`, `managed_by`, `member_id`, `added_by`) are deliberately
not added until slice 3 — adding nullable columns later is cheap.

## Data Model

Ship inventories are addressed through their vehicle, so the inventory name stops being
an identifier and the uniqueness rules only apply to hand-created inventories:

```ruby
add_index :inventories, :vehicle_id, unique: true, where: "vehicle_id IS NOT NULL"

add_index :inventories, "holder_type, holder_id, LOWER(name)", unique: true,
  where: "vehicle_id IS NULL",
  name: "index_inventories_on_holder_and_lower_name"

add_index :inventories, [:holder_type, :holder_id, :slug], unique: true,
  where: "vehicle_id IS NULL"
```

Consequences worth stating plainly:

- **One inventory per vehicle.** Implicit provisioning only works if "where does this
  deposit go" has exactly one answer. See Open Decisions for the cargo-grid-vs-locker
  question.
- **Two Ironclads produce two inventories both called "Ironclad Inventory".** Fine —
  nothing resolves by that string any more.
- The name validation on `Inventory` needs the same condition:
  `validates :name, uniqueness: {scope: [:holder_type, :holder_id]}, unless: :vehicle_id?`

### The name is stored, not derived

Write the label into the row at creation:

```ruby
record.name = "#{vehicle.name.presence || vehicle.model.name} Inventory"
```

Deriving it at render time would leave "Inventory" behind when a ship is sold or drops
out of an RSI hangar sync and `vehicle_id` nullifies. Stored, the orphan keeps a name
that still means something. Refreshing it while the vehicle exists (on ship rename) is
optional polish.

## Provisioning — lazily, on first write

The inventory does not exist until something is put in it.

- `GET /vehicles/:vehicle_id/inventory` with no row returns `200` and an unsaved shape
  (`id: null`, empty stock, name pre-computed from the ship). Nothing is persisted.
- The first `POST .../items` creates it:

```ruby
private def inventory
  @inventory ||= Inventory.find_or_create_by!(holder: current_resource_owner, vehicle: @vehicle) do |record|
    record.name = default_inventory_name_for(@vehicle)
  end
rescue ActiveRecord::RecordNotUnique
  retry # two first-deposits racing; the unique index on vehicle_id settles it
end
```

Why not create on first *visit*:

1. A GET that writes breaks caching, prefetching and safe retries.
2. Link prefetch or a crawler walking the hangar would create rows for untouched ships.
3. Someone with 60 ships would get an overview full of empty buckets — the opposite of
   the "where is my stuff" view this feature exists to provide.

`DELETE .../inventory` drops the entries and the row; the next deposit recreates it. That
is the "clear this ship's cargo" action, and it needs no separate concept.

## API

Routes mirror `config/routes/api/vehicle_loadouts_routes.rb`, which already nests
user-scoped resources under a vehicle:

```ruby
# config/routes/api/vehicle_inventories_routes.rb
resources :vehicles, only: [] do
  resource :inventory, controller: "vehicle_inventory", only: %i[show destroy] do
    resources :inventory_items, path: "items", controller: "vehicle_inventory_items",
      only: %i[index create update destroy] do
      post :import, on: :collection
    end

    get "stock", to: "vehicle_inventory_stock#index"
    get "stock/:slug", to: "vehicle_inventory_stock#show", as: "stock_item"
    patch "stock/:slug", to: "vehicle_inventory_stock#update"
    delete "stock/:slug", to: "vehicle_inventory_stock#destroy"
  end
end
```

Vehicles are addressed by id (or serial) rather than slug, because `vehicles.slug` derives
from the *optional* custom name and is nil for most ships. Reuse the loadouts lookup
verbatim:

```ruby
private def set_vehicle
  vehicle_id = params[:vehicle_id]
  @vehicle = if vehicle_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-/i)
    current_resource_owner.vehicles.find(vehicle_id)
  else
    current_resource_owner.vehicles.find_by!(serial: vehicle_id.upcase)
  end
end
```

Scoping from `current_resource_owner.vehicles` is the authorization boundary — the same
shape the hangar and fleet controllers use — so no policy has to branch on holder type.
Doorkeeper scopes are `hangar` / `hangar:read` for reads and `hangar:write` for writes,
matching `VehicleLoadoutsController`.

### Extract the shared controller body

`HangarInventoryItemsController` and `HangarInventoryStockController` differ from their
vehicle counterparts in exactly one method: how `@inventory` is found. Pull the rest into
a concern rather than copying 90 lines twice:

```ruby
module InventoryScoped
  extend ActiveSupport::Concern
  # index/create/update/destroy/import + stock actions, all against `inventory`
  # each including controller defines `inventory`
end
```

`HangarInventoryItemsController#inventory` resolves by inventory slug;
`VehicleInventoryItemsController#inventory` is the `find_or_create_by!` above. This is the
same de-duplication the model concerns already did, one layer up, and it is what keeps
slice 3 from being a third copy.

### OpenAPI components

`InventoryStockPosition` and `InventoryStockPositionInput`
(`app/api_components/shared/v1/schemas/`) are already context-neutral and shared between
fleet and hangar, so the vehicle stock endpoints reuse them as-is.

The inventory and item components are not neutral (`HangarInventory`,
`HangarInventoryItem`). Renaming them later is a breaking change for generated clients, so
introduce neutral `Inventory` / `InventoryItem` components **now** for the vehicle
endpoints and leave the hangar ones untouched. Both render from the same jbuilders, so the
shapes cannot drift; the hangar names can be deprecated in favour of the neutral ones
during slice 3.

## Frontend

The vehicle detail page (`pages/hangar/[id].vue`) gains a **Cargo** tab next to the
existing Loadouts one, registered the same way in `pages/hangar/[id]/routes.ts`.
Everything it needs already exists and is context-free:

| Component | Reused as-is |
|---|---|
| `Logistics/InventoryLedgerTables` | stock + log tables |
| `Logistics/StockItemPanel`, `StockItemModal` | stock position detail and edit |
| `Logistics/InventoryItemFilterForm` | filters |
| `Logistics/ComponentPicker` | linking entries to game components |
| `Hangar/Logistics/InventoryItemModal`, `CsvImportModal` | deposit / withdraw / import |

The two Hangar modals take an `inventory` prop and call the hangar mutations; they need a
mutation-injection prop (or a thin `Vehicle/Logistics/*` wrapper) to target the vehicle
endpoints. That is the only new component work.

On the overview (`/hangar/inventories`), ship inventories render through the existing
`InventoryPanel` with the ship as the subtitle — the panel already renders `location`
there, so passing the ship name needs no component change. Capacity comes free from
`models.cargo` (SCU) and the `CargoHold` records: show `312 / 400 SCU` and flag overfill,
but **do not validate** against it — players stash cargo outside the grid, and personal
inventory is not cargo.

## Edge Cases

- **Ship sold or removed by RSI sync.** `on_delete: :nullify` keeps the stock. Before
  nullifying, copy the ship's display name into `location` so the orphaned inventory still
  says where its contents came from. Needs a `before_destroy` on `Vehicle` (the FK alone
  cannot do the copy).
- **Loaners and bundles.** `vehicles.vehicle_id` self-reference: attach to the concrete
  vehicle row, never the bundle parent.
- **Hidden vehicles.** Inventories are private and user-scoped, so `vehicles.hidden` needs
  no special handling today. If a public ship view ever exposes cargo, `hidden` and
  `public` must gate it.
- **Withdrawal races.** Already handled — `InventoryLedgerEntry#withdrawal_does_not_exceed_stock`
  locks the inventory row, and it locks `Inventory` regardless of holder.

## Implementation Phases

1. **Schema + model** — `vehicle_id`, the three partial indexes, `Inventory#vehicle`,
   conditional name validation, `default_inventory_name_for`.
2. **Controller concern** — extract `InventoryScoped` from the hangar controllers; the
   hangar suite must stay green with zero test edits. This is a pure refactor and should
   land as its own commit.
3. **Vehicle endpoints** — routes, three controllers, neutral OpenAPI components, lazy
   provisioning, integration tests mirroring the hangar ones.
4. **Cargo tab** — vehicle page tab wiring the shared Logistics components.
5. **Overview integration** — ship subtitle on `InventoryPanel`, capacity indicator,
   `vehicleIdEq` filter on the aggregate stock endpoint.

## Files to Create/Modify

| Path | Change |
|---|---|
| `db/migrate/*_add_vehicle_to_inventories.rb` | new — column + partial indexes |
| `app/models/inventory.rb` | `belongs_to :vehicle`, conditional name uniqueness |
| `app/models/vehicle.rb` | `has_one :inventory`, `before_destroy` name freeze |
| `app/controllers/concerns/inventory_scoped.rb` | new — shared action bodies |
| `app/controllers/api/v1/hangar_inventory_{items,stock}_controller.rb` | include the concern |
| `app/controllers/api/v1/vehicle_inventory{,_items,_stock}_controller.rb` | new |
| `config/routes/api/vehicle_inventories_routes.rb` | new |
| `app/views/api/v1/vehicle_inventory*/` | new jbuilders (partials shared with hangar) |
| `app/api_components/v1/schemas/hangar/logistics/inventory{,_item}.rb` | new neutral components |
| `app/frontend/frontend/pages/hangar/[id]/cargo.vue` | new tab, alongside the existing `loadouts.vue` |
| `app/frontend/frontend/components/Vehicle/Logistics/*` | thin wrappers over the Hangar modals |
| `test/integration/api/v1/vehicle_inventory*_test.rb` | new, mirroring the hangar suite |

## Verification

- Integration coverage per endpoint mirroring the hangar suite, including the
  authorization cases (another user's vehicle → 404, unauthenticated → 401, and the
  import action inside the `hangar:write` guard — the gap that produced a 500 on the fleet
  side).
- A concurrency test for two simultaneous first deposits asserting exactly one inventory
  row and both entries recorded.
- A test that `GET .../inventory` on an untouched ship creates nothing:
  `assert_no_difference "Inventory.count"`.
- Phase 2 is proven by the existing hangar tests passing **unmodified**.

## Open Decisions

1. **One inventory per ship, or cargo grid vs personal inventory?** Star Citizen
   distinguishes them. Recommend one per ship for v1 — relaxing a unique index later is
   trivial and non-destructive, whereas an ambiguous deposit target defeats implicit
   provisioning. The upgrade shape is a `kind` enum with the index moved to
   `(vehicle_id, kind)`.
2. **Capacity: display or enforce?** Recommend display only, for the reasons above.
3. **Neutral API component names now or at slice 3?** Recommend now for the new endpoints
   (renames are breaking; additions are not).
