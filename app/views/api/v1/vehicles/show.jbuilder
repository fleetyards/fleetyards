# frozen_string_literal: true

json.partial!("api/v1/vehicles/vehicle", vehicle: @vehicle)

json.fleets @fleets do |fleet|
  json.id fleet.id
  json.fid fleet.fid
  json.name fleet.name
  json.slug fleet.slug
end
