# frozen_string_literal: true

json.cache! ["v5", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle.user, vehicle, vehicle.launch_port_location&.link_cache_key, vehicle.model&.manufacturer, I18n.locale] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)
end
