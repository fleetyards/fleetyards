# frozen_string_literal: true

json.cache! ["v5", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle, vehicle.linked_location&.link_cache_key, I18n.locale] do
  json.partial!("api/v1/vehicles/base", vehicle:)
end
