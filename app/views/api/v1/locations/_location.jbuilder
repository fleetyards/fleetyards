# frozen_string_literal: true

json.cache! ["v2", location, location.facts, location.parent, location.parent&.parent, ::ScData::Source.current] do
  json.partial! "api/v1/locations/base", location:
end
