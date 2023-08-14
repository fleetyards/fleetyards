# frozen_string_literal: true

json.cache! ["v1", celestial_object] do
  json.partial!("api/v1/celestial_objects/base", celestial_object:)
  json.partial! "api/shared/dates", record: celestial_object
end
