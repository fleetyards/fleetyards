# frozen_string_literal: true

json.id trade_route.id

json.commodity do
  json.id trade_route.commodity.id
  json.name trade_route.commodity.name
  json.slug trade_route.commodity.slug
end

json.origin_terminal do
  json.partial! "api/v1/terminals/base", terminal: trade_route.origin_terminal
end
json.destination_terminal do
  json.partial! "api/v1/terminals/base", terminal: trade_route.destination_terminal
end

json.price_origin trade_route.price_origin.to_f
json.price_destination trade_route.price_destination.to_f
json.profit_per_scu trade_route.profit_per_scu.to_f
json.scu_origin trade_route.scu_origin
json.scu_destination trade_route.scu_destination
json.container_sizes trade_route.container_sizes
json.distance trade_route.distance&.to_f
json.origin_price_updated_at trade_route.origin_price_updated_at&.utc&.iso8601
json.destination_price_updated_at trade_route.destination_price_updated_at&.utc&.iso8601

json.loadable_scu trade_route.loadable_scu
json.load_limit trade_route.load_limit
json.unflyable_reason trade_route.unflyable_reason
json.other_destinations trade_route.has_attribute?(:group_size) ? trade_route.group_size - 1 : nil
json.investment trade_route.investment&.to_f
json.profit_per_run trade_route.profit_per_run&.to_f
json.profit_per_distance trade_route.profit_per_distance&.to_f&.round(2)
