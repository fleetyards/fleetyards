# frozen_string_literal: true

json.id item_price.id

json.item_id item_price.item_id
json.item_type item_price.item_type

json.price item_price.price&.to_f
json.time_range item_price.time_range
json.price_type item_price.price_type

json.location item_price.location
json.location_url item_price.location_url

if item_price.shop
  json.shop do
    json.name item_price.shop.name
    json.slug item_price.shop.slug
    json.location do
      json.partial! "api/v1/locations/link", location: item_price.shop.location
    end
  end
else
  json.shop nil
end

json.scu item_price.scu
json.source_updated_at item_price.source_updated_at&.utc&.iso8601

json.partial! "api/shared/dates", record: item_price
