# frozen_string_literal: true

json.id slot_candidate.id
json.position slot_candidate.position
json.username slot_candidate.fleet_squadron_membership.fleet_membership&.user&.username
json.avatar do
  json.partial! "api/v1/shared/file", record: slot_candidate.fleet_squadron_membership.fleet_membership&.user, attr: :avatar
end
json.passed_at slot_candidate.try(:passed_at)&.utc&.iso8601
if slot_candidate.vehicle.present?
  json.vehicle do
    json.partial! "api/v1/fleet_squadron_vehicles/fleet_squadron_vehicle", vehicle: slot_candidate.vehicle
  end
else
  json.vehicle nil
end
