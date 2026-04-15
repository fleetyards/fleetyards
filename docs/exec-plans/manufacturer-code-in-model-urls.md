# Add Manufacturer Codes to Model URLs

## Context

CIG may add ships with the same name from different manufacturers. Current URLs use only the ship name slug (e.g., `/ships/mercury-star-runner`), which would collide. Adding the manufacturer code prefix makes URLs unique per manufacturer (e.g., `/ships/CRUS-mercury-star-runner`).

## Decisions

- **Slug format**: `CRUS-mercury-star-runner` (uppercase code, dash, lowercase parameterized name)
- **Name uniqueness**: Scope to `manufacturer_id` instead of global
- **Old URLs**: 301 redirect via `legacy_slug` column

---

## Step 1: Database Migration

Create migration to add `legacy_slug` column, update existing slugs, and adjust uniqueness.

**File**: `db/migrate/XXXXXXXX_add_manufacturer_code_to_model_slugs.rb`

- Add `legacy_slug` (string, nullable) to `models` with index
- Copy current `slug` to `legacy_slug` for all models with a manufacturer
- Update `slug` to `"#{manufacturer.code}-#{current_slug}"` (code is already uppercase in DB)
- Remove old unique index on `name`, add `uniqueness: { scope: :manufacturer_id }` index
- Use `update_columns` to skip callbacks

## Step 2: Model Layer - Slug Generation

**File**: `app/models/model.rb`

Update `update_slugs` (line 636-639):

```ruby
private def update_slugs
  if manufacturer.present?
    self.slug = "#{manufacturer.code}-#{name.parameterize}"
  else
    self.slug = generate_slug(name)
  end
  self.rsi_slug = generate_slug(rsi_name)
end
```

Update validation (line 230):

```ruby
validates :name, presence: true, uniqueness: { scope: :manufacturer_id }
```

## Step 3: API Controller - Legacy Slug Redirects

**File**: `app/controllers/api/v1/models_controller.rb`

Extract a shared `find_model_by_slug!` method that:

1. Queries `slug`, `rsi_slug`, and `legacy_slug` with OR
2. If found via `legacy_slug` or `rsi_slug`, returns 301 redirect to canonical slug URL
3. Used by `show` and all 11 member actions

```ruby
private def find_model_by_slug!
  @model = Model.visible.active
    .where(slug: params[:slug])
    .or(Model.where(rsi_slug: params[:slug]))
    .or(Model.where(legacy_slug: params[:slug]))
    .first!

  if @model.slug != params[:slug]
    redirect_to url_for(slug: @model.slug), status: :moved_permanently
    return false
  end
  true
end
```

## Step 4: Frontend Controller - Legacy Slug Redirects

**File**: `app/controllers/frontend/base_controller.rb`

Update `model_record` (line 224-225) to also check `legacy_slug`:

```ruby
Model.where(slug: slug).or(Model.where(legacy_slug: slug))
```

Add redirect logic in `model`, `model_images`, `model_videos` actions when found via legacy slug.

## Step 5: Route Updates

**File**: `config/routes/frontend_routes.rb`

Update legacy redirect:

```ruby
get "ships/mercury", to: redirect("/ships/CRUS-mercury-star-runner")
```

No changes needed to route patterns - `:slug` param accepts any format.

## Step 6: Seeds

**File**: `db/seeds.rb`

Update hardcoded slug `"freelancer"` to `"MISC-freelancer"` (or whatever the correct manufacturer code is for MISC).

## Step 7: Test Updates

Update hardcoded slugs in specs:

- `spec/loaders/hangar_sync_spec.rb`
- `spec/loaders/rsi/models_loader_spec.rb`
- `spec/loaders/sc_data/models_loader_spec.rb`
- Any other specs with hardcoded model slugs

Add tests for 301 redirect behavior on legacy slugs.

## No Frontend Changes Needed

- Vue router `:slug` param is format-agnostic
- All components use `model.slug` from API response - automatically gets new format
- Orval-generated API services pass slug as path param - transparent
- Hangar/wishlist stores populated from API on auth - auto-updated

## Verification

1. `bin/rails db:migrate` - verify migration runs cleanly
2. `bin/rails console` - check `Model.first.slug` includes manufacturer code prefix
3. `bundle exec rspec` - all tests pass
4. Manual: visit `/ships/mercury-star-runner` -> should 301 to `/ships/CRUS-mercury-star-runner`
5. Manual: API call `GET /api/v1/models/mercury-star-runner` -> 301 redirect
6. Manual: ship pages, hangar, compare all work with new slugs
