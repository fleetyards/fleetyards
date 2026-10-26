# frozen_string_literal: true

json.partial! "api/v1/fleet_shopping_lists/fleet_shopping_list", fleet_shopping_list: @fleet_shopping_list
json.items @trip_plan.lines, partial: "api/v1/carts/line", as: :line
json.totals do
  json.total @trip_plan.total.to_f
  json.items_count @trip_plan.lines.size
  json.quantity @trip_plan.lines.sum { |line| line.cart_item.quantity }
  json.unavailable_count @trip_plan.unavailable_count
  json.stops_count @trip_plan.groups.size
end
