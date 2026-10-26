# frozen_string_literal: true

json.items @trip_plan.lines, partial: "api/v1/carts/line", as: :line
json.groups @trip_plan.groups, partial: "api/v1/carts/group", as: :group
json.totals do
  json.total @trip_plan.total.to_f
  json.items_count @trip_plan.lines.size
  json.unavailable_count @trip_plan.unavailable_count
  json.stops_count @trip_plan.groups.size
end
