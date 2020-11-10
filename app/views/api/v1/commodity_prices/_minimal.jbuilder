# frozen_string_literal: true

json.cache! ['v1', commodity_price] do
  json.partial! 'api/v1/commodity_prices/base', commodity_price: commodity_price
  json.partial! 'api/shared/dates', record: commodity_price
end
