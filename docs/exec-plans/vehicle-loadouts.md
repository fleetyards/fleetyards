# Vehicle Loadout System

## Context

Fleetyards tracks ships and their hardpoints from Star Citizen game data, but weapon stats are not extracted (commented out since implementation) and there's no way for users to store custom loadout configurations on their vehicles. The mission builder needs loadout data to let organizers specify equipment requirements and members to show what they're bringing.

This feature has three parts: enable missing component stats, add per-vehicle loadout storage, and integrate with erkul.games/spviewer.eu.

Resolves #3792.

## Current State

### What Exists
- **945 weapon components** in DB — but `type_data` is nil (parsing commented out at `items_parser.rb:380`)
- **735 turret components** — `type_data` nil (commented out at line 388)
- **0 missile components** — not being imported
- **ModelHardpointLoadout** — stores alternative component options per hardpoint on a model template (admin-managed)
- **Vehicle** model has `vehicle_modules` and `vehicle_upgrades` (RSI pledge modules) but no hardpoint-level loadout storage
- **erkul_identifier** field on Model — used for deep-linking to `erkul.games/ship/{id}`
- **Hardpoint** detail views link out to erkul and spviewer

### What's Missing
- Weapon/missile/turret/armor stats in `type_data`
- Per-vehicle loadout storage (component selections per hardpoint)
- Loadout management API and UI
- Erkul/spviewer loadout URL storage
- Component stat summaries (DPS, shield HP, etc.)

## Phase 1 — Enable Weapon & Component Stats

### Uncomment and Implement Stats Extraction

In `app/lib/sc_data/parser/items_parser.rb`, uncomment and structure the following:

**Weapons** (line 380):
```ruby
if values.dig("Components", "SCItemWeaponComponentParams")
  weapon_data = values.dig("Components", "SCItemWeaponComponentParams")
  fire_actions = weapon_data.dig("fireActions", "SWeaponActionFireSingleParams") ||
                 weapon_data.dig("fireActions", "SWeaponActionSequenceParams")
  fire_actions = fire_actions.is_a?(Array) ? fire_actions.first : fire_actions

  item[:type_data] = {
    weapon_class: weapon_data["weaponClass"],
    fire_rate: fire_actions&.dig("fireRate")&.to_f,
    heat_per_shot: fire_actions&.dig("heatPerShot")&.to_f,
    damage_per_shot: extract_weapon_damage(fire_actions),
    pellets_per_shot: fire_actions&.dig("launchParams", "SProjectileLauncher", "pelletCount")&.to_i,
    speed: fire_actions&.dig("launchParams", "SProjectileLauncher", "speed")&.to_f,
    range: fire_actions&.dig("launchParams", "SProjectileLauncher", "lifetime")&.to_f,
    ammo_cost: fire_actions&.dig("launchParams", "SProjectileLauncher", "ammoCost")&.to_i
  }.compact
end
```

**Missiles** (line 376):
```ruby
if values.dig("Components", "SCItemMissileParams")
  missile_data = values.dig("Components", "SCItemMissileParams")
  item[:type_data] = {
    damage: missile_data.dig("explosionParams", "damage")&.to_f,
    radius: missile_data.dig("explosionParams", "radius")&.to_f,
    lock_time: missile_data.dig("targetingParams", "lockTime")&.to_f,
    lock_range: missile_data.dig("targetingParams", "lockRange")&.to_f,
    tracking_signal: missile_data.dig("targetingParams", "trackingSignalType"),
    speed: missile_data.dig("GCSParams", "linearSpeed")&.to_f
  }.compact
end
```

**Vehicle Armor** (line 384):
```ruby
if values.dig("Components", "SCItemVehicleArmorParams")
  armor_data = values.dig("Components", "SCItemVehicleArmorParams")
  item[:type_data] = {
    damage_physical: armor_data.dig("damageMultiplier", "DamageInfo", "DamagePhysical")&.to_f,
    damage_energy: armor_data.dig("damageMultiplier", "DamageInfo", "DamageEnergy")&.to_f,
    damage_distortion: armor_data.dig("damageMultiplier", "DamageInfo", "DamageDistortion")&.to_f,
    damage_thermal: armor_data.dig("damageMultiplier", "DamageInfo", "DamageThermal")&.to_f,
    damage_biochemical: armor_data.dig("damageMultiplier", "DamageInfo", "DamageBiochemical")&.to_f,
    damage_stun: armor_data.dig("damageMultiplier", "DamageInfo", "DamageStun")&.to_f,
    signal_infrared: armor_data.dig("signalCrossSection", "SItemSignalEmission", "Infrared")&.to_f,
    signal_electromagnetic: armor_data.dig("signalCrossSection", "SItemSignalEmission", "Electromagnetic")&.to_f,
    signal_cross_section: armor_data.dig("signalCrossSection", "SItemSignalEmission", "CrossSection")&.to_f
  }.compact
end
```

**Note:** The exact JSON paths need verification against actual SC data files. The above is derived from the game data structure — first implementation should log the raw data and adjust paths.

### MaintenanceTask

`Maintenance::ReimportComponentStatsTask` — re-runs the items import to populate weapon/missile/armor type_data for existing components.

### Verification
- `Component.where(category: 'weapons').where.not(type_data: nil).count` should equal `Component.where(category: 'weapons').count` (or close)
- Spot-check: CF-227 Badger should have fire_rate, damage_per_shot, speed values

## Phase 2 — Vehicle Loadout Storage

### Data Model

```
vehicle_loadouts
  id              :uuid PK
  vehicle_id      :uuid FK → vehicles, NOT NULL
  name            :string NOT NULL ("PvE Setup", "Mining Escort")
  active          :boolean default: false
  erkul_url       :string (erkul.games share URL, nullable)
  spviewer_url    :string (spviewer share URL, nullable)
  timestamps

  Indexes: (vehicle_id), (vehicle_id, name) unique

vehicle_loadout_hardpoints
  id                  :uuid PK
  vehicle_loadout_id  :uuid FK → vehicle_loadouts, NOT NULL
  model_hardpoint_id  :uuid FK → model_hardpoints, NOT NULL
  component_id        :uuid FK → components (nullable — empty slot)
  timestamps

  Indexes: (vehicle_loadout_id), (vehicle_loadout_id, model_hardpoint_id) unique
```

### Models

**VehicleLoadout**
- `belongs_to :vehicle`
- `has_many :vehicle_loadout_hardpoints, dependent: :destroy`
- `accepts_nested_attributes_for :vehicle_loadout_hardpoints`
- `validates :name, presence: true, uniqueness: { scope: :vehicle_id }`
- Scope: `active` — `where(active: true)`

**VehicleLoadoutHardpoint**
- `belongs_to :vehicle_loadout`
- `belongs_to :model_hardpoint`
- `belongs_to :component, optional: true`
- `validates :model_hardpoint_id, uniqueness: { scope: :vehicle_loadout_id }`

### "Create from Default" Flow

When a user creates a loadout, pre-populate with the model's default components:
```ruby
def create_from_defaults!
  vehicle.model.model_hardpoints.each do |mh|
    vehicle_loadout_hardpoints.find_or_create_by!(model_hardpoint_id: mh.id) do |vlh|
      vlh.component_id = mh.component_id
    end
  end
end
```

### API

- `GET /vehicles/:id/loadouts` — list loadouts for a vehicle
- `POST /vehicles/:id/loadouts` — create loadout (optionally from defaults)
- `GET /vehicles/:id/loadouts/:id` — show loadout with hardpoint details
- `PUT /vehicles/:id/loadouts/:id` — update loadout
- `DELETE /vehicles/:id/loadouts/:id` — delete loadout
- `PUT /vehicles/:id/loadouts/:id/activate` — set as active loadout

## Phase 3 — Erkul/SPViewer Integration

### Link-Based (Phase 3a)

Store erkul and spviewer URLs on `VehicleLoadout`:
- Users paste their erkul loadout URL (`erkul.games/loadout/{code}`)
- Users paste their spviewer URL
- Display links on loadout detail and fleet vehicle views

### Deep-Link Generation (Phase 3b — investigation needed)

Research whether we can generate erkul/spviewer links from our loadout data:
- Erkul loadout codes — what format? Can we reverse-engineer?
- SPViewer HangarSync extension — can we provide data in their format?
- SC-Open.dev community standard — JSON-based hangar/loadout exchange format

**This phase requires hands-on investigation.** Create a research spike:
1. Visit erkul.games, create a loadout, examine the URL and any export options
2. Check if erkul has an API or documented import format
3. Check SPViewer docs for import mechanisms
4. Review SC-Open.dev spec at `docs.starcitizen.fans`

### Future: Import (Phase 3c)

If erkul/spviewer formats are parseable:
- "Import from Erkul" button — paste URL, parse component selections, populate loadout
- "Import from SPViewer" — same flow
- This is explicitly future work pending the Phase 3b research

## Phase 4 — Component Stats Display

### Loadout Summary

Calculate and display per-loadout:
- **Total DPS** = Σ(weapon.damage_per_shot × weapon.fire_rate) across all weapon hardpoints
- **Burst DPS** = DPS accounting for magazine/heat limits
- **Shield HP** = Σ(shield.max_health) across shield hardpoints
- **Shield Regen** = Σ(shield.max_regen)
- **Power Draw** = total power consumption (from power connection data)
- **Cooling Capacity** = total cooling (from cooler type_data)
- **Quantum Range** = from QD type_data + fuel capacity

### Component Detail View

On ship detail page and loadout editor:
- Show component stats inline per hardpoint
- Weapon hardpoints: damage, fire rate, DPS
- Shield: HP, regen
- Power plants: output
- Coolers: cooling rate
- QD: speed, range, fuel consumption

### Note

This is NOT a full DPS calculator — erkul does that much better. We provide a quick summary so users can compare loadouts at a glance and mission creators can assess what members are bringing.

## Phase 5 — Frontend

### Hangar: Loadout Management

On vehicle detail (hangar page):
- "Loadouts" tab/section
- Create/rename/delete loadouts
- Set active loadout
- Paste erkul/spviewer URLs
- Per-hardpoint component selector (dropdown of compatible components)
- Stat summary per loadout

### Ship Detail: Component Stats

Extend hardpoint display to show:
- Default component stats (damage, fire rate, etc.)
- Link to erkul/spviewer for full analysis

### Fleet Vehicle View

Extend fleet vehicle cards to show:
- Active loadout name
- Erkul/spviewer links if set
- Quick stat summary

## Implementation Order

1. **Phase 1** — Weapon stats import (~2 days)
2. **Phase 2** — Loadout storage + API (~3 days)
3. **Phase 4** — Component stats display on ship detail (~2 days)
4. **Phase 5a** — Loadout management UI in hangar (~3 days)
5. **Phase 3a** — Erkul/spviewer URL storage + links (~1 day)
6. **Phase 3b** — Research spike for deeper integration (~investigation)
7. **Phase 5b** — Fleet vehicle loadout display (~1 day)

## Files to Create/Modify

**Create:**
- `db/migrate/xxx_create_vehicle_loadouts.rb`
- `app/models/vehicle_loadout.rb`
- `app/models/vehicle_loadout_hardpoint.rb`
- `app/controllers/api/v1/vehicle_loadouts_controller.rb`
- `app/policies/vehicle_loadout_policy.rb`
- `app/views/api/v1/vehicle_loadouts/`
- `app/api_components/v1/schemas/vehicles/vehicle_loadout.rb`
- `spec/requests/api/v1/vehicle_loadouts/`
- `spec/factories/vehicle_loadouts.rb`
- `app/tasks/maintenance/reimport_component_stats_task.rb`
- Frontend: loadout components + management UI

**Modify:**
- `app/lib/sc_data/parser/items_parser.rb` — uncomment weapon/missile/armor/turret stats
- `app/models/vehicle.rb` — add `has_many :vehicle_loadouts`
- `app/views/api/v1/components/_base.jbuilder` — ensure type_data is exposed
- `app/frontend/frontend/components/Models/Hardpoints/` — add stat display
- Routes for vehicle loadouts

## Verification

1. SC data import → weapon components have type_data with damage/fire_rate
2. `POST /vehicles/:id/loadouts` → creates loadout with default components
3. `PUT /vehicles/:id/loadouts/:id` → swap a weapon component, DPS changes
4. Ship detail page shows weapon stats per hardpoint
5. Hangar: create loadout, select components, paste erkul URL, see stat summary
6. Fleet vehicle view shows active loadout name + erkul link
