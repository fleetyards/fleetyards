# Remove Tableless Models

These 7 models have no backing database table on the vue3 branch and should be removed along with all their references.

## Phase 1: Trading/Commerce (heaviest dependencies)

### Commodity
- `app/models/commodity.rb`
- `app/models/commodity_price.rb`
- `app/models/commodity_buy_price.rb`
- `app/models/commodity_rental_price.rb`
- `app/models/commodity_sell_price.rb`
- `app/controllers/api/v1/commodities_controller.rb`
- `app/controllers/api/v1/filters/commodity_prices_controller.rb`
- `app/uploaders/commodity_store_image_uploader.rb`
- Remove commodity references from `app/views/api/v1/search/_base.jbuilder`
- Remove commodity locale keys from `config/locales/en/*.yml`

### Shop & ShopCommodity
- `app/models/shop.rb`
- `app/models/shop_commodity.rb`
- Remove shop references from `app/views/api/v1/search/_base.jbuilder`
- Remove shop locale keys from `config/locales/en/*.yml`

### Trading infrastructure
- `app/jobs/prices_job.rb`
- `app/lib/trading_data/exporter.rb`
- `app/lib/trading_data/importer.rb`
- `spec/jobs/prices_job_spec.rb`
- Remove routes for commodities, commodity_prices, shops, shop_commodities

## Phase 2: Star map

### Starsystem
- `app/models/starsystem.rb`
- Remove starsystem references from `app/views/api/v1/search/_base.jbuilder`
- Remove starsystem locale keys from `config/locales/en/*.yml`

### CelestialObject
- `app/models/celestial_object.rb`
- Remove reference in `app/models/starsystem.rb` (removed in same phase)
- Remove from `app/views/api/v1/search/_base.jbuilder`

### Station
- `app/models/station.rb`
- Remove station references from `app/api_components/shared/v1/schemas/enums/component_type_enum.rb`
- Remove station references from `app/api_components/shared/v1/schemas/enums/gallery_type_enum.rb`
- Remove from `app/views/api/v1/search/_base.jbuilder`
- Remove station locale keys from `config/locales/en/*.yml` and `config/locales/fr/resources.yml`
- Check `db/data/20250411071344_prefill_image_gallery_fields.rb` for station references
- Remove `station_id` column from `docks` table if no longer needed

## Phase 3: Cleanup

### Shared files to update
- `app/controllers/frontend/base_controller.rb` — references CelestialObject, Shop, Starsystem, Station
- `app/views/api/v1/search/_base.jbuilder` — references all of the above
- Remove unused routes from `config/routes.rb`
- Remove any API schema definitions for removed resources
- Run test suite and fix any remaining references
