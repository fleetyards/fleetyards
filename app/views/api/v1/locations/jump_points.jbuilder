# frozen_string_literal: true

json.array! @jump_points do |entry|
  json.location do
    json.partial! "api/v1/locations/link", location: entry.location
  end
  json.system_id entry.system_id
  json.destination_name entry.destination_name
  json.destination_system_id entry.destination_system_id
end
