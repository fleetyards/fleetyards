# frozen_string_literal: true

json.array! @fleet_squadron_ship_requests do |fleet_squadron_ship_request|
  json.partial! "api/v1/fleet_squadron_ship_requests/fleet_squadron_ship_request", fleet_squadron_ship_request:
end
