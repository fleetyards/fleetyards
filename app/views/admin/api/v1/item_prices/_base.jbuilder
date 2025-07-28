# frozen_string_literal: true

json.id item_price.id

json.item_id item_price.item_id
json.item_type item_price.item_type

json.price item_price.price&.to_f
json.time_range item_price.time_range
json.price_type item_price.price_type

json.location item_price.location
json.location_url item_price.location_url

json.partial! "api/shared/dates", record: item_price
