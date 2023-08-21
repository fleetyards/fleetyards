# frozen_string_literal: true

json.id trade_route.id

json.origin do
  json.partial! "api/v1/trade_routes/leg", leg: trade_route.origin
end

json.destination do
  json.partial! "api/v1/trade_routes/leg", leg: trade_route.destination
end

json.commodity do
  json.partial! "api/v1/trade_routes/commodity", commodity: trade_route.origin.commodity_item
end

json.buy_price trade_route.origin.sell_price&.to_f
json.average_buy_price trade_route.origin.average_sell_price&.to_f
json.sell_price trade_route.destination.buy_price&.to_f
json.average_sell_price trade_route.destination.average_buy_price&.to_f
json.profit_per_unit trade_route.profit_per_unit&.to_f
json.average_profit_per_unit trade_route.average_profit_per_unit&.to_f
json.profit_per_unit_percent trade_route.profit_per_unit_percent&.to_f
json.average_profit_per_unit_percent trade_route.average_profit_per_unit_percent&.to_f

json.partial! "api/shared/dates", record: trade_route
