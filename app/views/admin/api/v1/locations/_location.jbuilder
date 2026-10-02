# frozen_string_literal: true

json.cache! ["admin", "v1", location, location.facts, location.parent, location.parent&.parent, ::ScData::Source.current] do
  json.partial! "admin/api/v1/locations/base", location: location
end
