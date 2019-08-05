# frozen_string_literal: true

json.cache! ['v1', trade_route] do
  json.partial! 'api/v1/trade_routes/base', trade_route: trade_route
  json.partial! 'api/shared/dates', record: trade_route
end
