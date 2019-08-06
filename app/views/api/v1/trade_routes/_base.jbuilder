# frozen_string_literal: true

json.origin do
  json.partial! 'api/v1/trade_routes/leg', leg: trade_route.origin
end
json.destination do
  json.partial! 'api/v1/trade_routes/leg', leg: trade_route.destination
end
json.commodity do
  json.partial! 'api/v1/trade_routes/commodity', commodity: trade_route.origin.commodity_item
end
json.buy_price trade_route.origin.sell_price
json.sell_price trade_route.destination.buy_price
json.profit_per_unit trade_route.profit_per_unit
json.profit_per_unit_percent trade_route.profit_per_unit_percent
