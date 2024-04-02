# frozen_string_literal: true

json.id model_price.id

json.price model_price.price&.to_f
json.time_range model_price.time_range
json.price_type model_price.price_type

json.location model_price.location
json.location_url model_price.location_url

json.partial! "api/shared/dates", record: model_price
