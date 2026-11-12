# frozen_string_literal: true

json.items do
  json.array! @fleet_squadrons, partial: "api/v1/fleet_squadrons/fleet_squadron", as: :fleet_squadron,
    locals: {flight_counts: @flight_counts}
end
json.partial! "api/shared/meta", result: @fleet_squadrons
