# frozen_string_literal: true

json.id commodity_price.id

json.confirmed commodity_price.confirmed
json.price commodity_price.price&.to_f
json.shop_commodity_id commodity_price.shop_commodity_id
json.time_range commodity_price.time_range
json.type commodity_price.type

json.partial! "api/shared/dates", record: commodity_price
