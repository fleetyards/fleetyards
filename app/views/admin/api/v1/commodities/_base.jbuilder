# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug
json.commodity_type commodity.commodity_type
json.description commodity.description

json.store_image do
  json.partial! "api/v1/shared/file", record: commodity, attr: :store_image
end

json.buy_price commodity.buy_price&.to_f
json.sell_price commodity.sell_price&.to_f

# Prices and trade data are datacore-only, so a commodity is matched to UEX by
# these rather than by name -- an admin needs to see and correct the mapping.
json.uex_id commodity.uex_id
json.uex_code commodity.uex_code

json.sc_key commodity.sc_key
json.sc_ref commodity.sc_ref
json.version commodity.version

json.partial! "api/shared/dates", record: commodity
