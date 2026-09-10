# frozen_string_literal: true

json.cache! ["v1", model, ::ScData::Source.current, Manufacturer.artwork_version, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end
