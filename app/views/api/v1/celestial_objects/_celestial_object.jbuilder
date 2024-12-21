# frozen_string_literal: true

json.cache! ["v1", celestial_object, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/celestial_objects/base", celestial_object:, extended: local_assigns.fetch(:extended, false))
end
