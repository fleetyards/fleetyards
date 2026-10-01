# frozen_string_literal: true

json.cache! ["v1", location, location.facts, location.parent, ::ScData::Source.current] do
  json.partial! "api/v1/locations/base", location:
end
