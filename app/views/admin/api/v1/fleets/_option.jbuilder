# frozen_string_literal: true

json.cache! ["admin/v1/fleets/option", fleet] do
  json.id fleet.id
  json.fid fleet.fid
  json.name fleet.name
  json.slug fleet.slug
end
