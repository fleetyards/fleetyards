# Fleet Member Worldmap

Fleet members currently have no location data. This plan adds a worldmap view showing where fleet members are located geographically. Users set their location (e.g. "Berlin, Germany") in their profile settings, which gets geocoded to lat/lng coordinates server-side. The map is rendered using Leaflet with OpenStreetMap tiles.

## Phase 1: Database and Geocoding

### Migration

**Create** `db/migrate/YYYYMMDDHHMMSS_add_location_to_users.rb`

```ruby
add_column :users, :location, :string
add_column :users, :latitude, :decimal, precision: 10, scale: 6
add_column :users, :longitude, :decimal, precision: 10, scale: 6
```

### Geocoder Gem

**Add** to `Gemfile`:

```ruby
gem 'geocoder'
```

**Create** `config/initializers/geocoder.rb`:

```ruby
Geocoder.configure(
  lookup: :nominatim,
  http_headers: { 'User-Agent' => 'FleetYards (fleetyards.net)' },
  units: :km,
  cache: Rails.cache,
  cache_options: { expiration: 1.day }
)
```

### User Model

**Edit** `app/models/user.rb`:

- Add `geocoded_by :location`
- Add `after_validation :geocode, if: :will_save_change_to_location?`
- When location is cleared, also clear latitude/longitude

## Phase 2: Backend API Changes

### User Profile API

**Edit** `app/controllers/api/v1/users_controller.rb`:

- Add `:location` to `user_params` permitted list

**Edit** `app/views/api/v1/users/_base.jbuilder`:

- Add `json.location user.location if user.location.present?`

**Edit** `app/api_components/v1/schemas/inputs/user_update_input.rb`:

- Add `location: { type: :string, nullable: true }`

**Edit** `app/api_components/v1/schemas/user.rb`:

- Add `location: { type: :string }`

### Fleet Member API

**Edit** `app/views/api/v1/fleet_members/_base.jbuilder`:

- Add `json.latitude member.user.latitude`
- Add `json.longitude member.user.longitude`

**Edit** `app/api_components/v1/schemas/fleets/fleet_member.rb`:

- Add `latitude: { type: :number, format: :double, nullable: true }`
- Add `longitude: { type: :number, format: :double, nullable: true }`

### Schema Regeneration

- Run `./bin/generate-schema`
- Run `bundle exec standardrb --fix` on changed Ruby files

## Phase 3: Frontend — Profile Settings

### Install Dependencies

```bash
pnpm add leaflet @vue-leaflet/vue-leaflet
pnpm add -D @types/leaflet
```

### Profile Settings

**Edit** `app/frontend/frontend/pages/settings/profile.vue`:

- Add `location` field with `defineField("location")`
- Add `FormInput` with icon `fa-duotone fa-location-dot` and translation key `user.location`
- Place it after the RSI Handle field, before the `<hr>`
- Initialize from `sessionStore.currentUser?.location`
- Add to `setupForm()` method

### Translations

**Edit** `app/frontend/translations/en/labels.json`:

- Add `"user": { "location": "Location" }` (or update existing user labels)

## Phase 4: Frontend — Worldmap Component and Route

### WorldMap Component

**Create** `app/frontend/frontend/components/Fleets/MembersWorldMap/index.vue`:

- Import `LMap`, `LTileLayer`, `LMarker`, `LPopup` from `@vue-leaflet/vue-leaflet`
- Import Leaflet CSS
- Props: `members: FleetMember[]`
- Filter members to only those with `latitude` and `longitude` present
- Render Leaflet map with OpenStreetMap tile layer
- Each member gets a marker with a popup showing username and avatar
- Map auto-fits bounds to visible markers
- Responsive height (e.g. `calc(100vh - 300px)`)

### Worldmap Page

**Create** `app/frontend/frontend/pages/fleets/[slug]/members/worldmap.vue`:

- Follows same pattern as `members/index.vue`
- Props: `fleet`, `membership`, `resourceAccess`
- Fetches all fleet members (no pagination — uses a large perPage or loops pages)
- Renders `BreadCrumbs`, `Heading`, and `MembersWorldMap` component
- Shows count of members with locations set

### Route Registration

**Edit** `app/frontend/frontend/pages/fleets/[slug]/members/routes.ts`:

- Add route:
  ```ts
  {
    path: "worldmap/",
    name: "fleet-members-worldmap",
    component: () => import("@/frontend/pages/fleets/[slug]/members/worldmap.vue"),
    meta: {
      title: "fleets.members.worldmap",
      needsAuthentication: true,
      customTitle: true,
    },
  }
  ```

### Navigation Toggle

**Edit** `app/frontend/frontend/pages/fleets/[slug]/members/index.vue`:

- Add a button/link to navigate to the worldmap view (e.g. globe icon button in the header area)

**Edit** `app/frontend/frontend/pages/fleets/[slug]/members/worldmap.vue`:

- Add a button/link to navigate back to the list view

### Translations

**Edit** `app/frontend/translations/en/headlines.json`:

- Add `"fleets": { "members": { "worldmap": "Member Worldmap" } }` (nested in existing structure)

**Edit** `app/frontend/translations/en/nav.json`:

- Add `"fleets": { "members": { "worldmap": "Worldmap" } }` (nested in existing structure)

## Phase 5: Regenerate API Client and Lint

- Run `./bin/generate-schema` to update OpenAPI spec
- Run Orval to regenerate frontend API types and services
- Run `bundle exec standardrb --fix` on all changed Ruby files
- Run `pnpm lint:fix` on all changed frontend files

## Verification

1. `rspec` — no backend regressions
2. `pnpm test` — no frontend regressions
3. Manual: set location in profile settings, verify geocoding stores lat/lng
4. Manual: navigate to fleet members worldmap, verify markers appear for members with locations
5. Members without location are simply not shown on the map
