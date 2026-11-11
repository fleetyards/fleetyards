# frozen_string_literal: true

json.id fleet_squadron_ship_request.id
json.member do
  json.partial! "api/v1/fleet_members/fleet_member", member: fleet_squadron_ship_request.fleet_squadron_membership.fleet_membership
end
json.requested_by_username fleet_squadron_ship_request.requested_by&.user&.username
json.vehicle do
  json.partial! "api/v1/fleet_squadron_vehicles/fleet_squadron_vehicle", vehicle: fleet_squadron_ship_request.vehicle
end
json.partial! "api/shared/dates", record: fleet_squadron_ship_request
