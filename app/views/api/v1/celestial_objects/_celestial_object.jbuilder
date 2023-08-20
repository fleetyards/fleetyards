# frozen_string_literal: true

json.cache! ["v1", celestial_object] do
  json.partial!("api/v1/celestial_objects/base", celestial_object:, extended: local_assigns.fetch(:extended, false))
end
