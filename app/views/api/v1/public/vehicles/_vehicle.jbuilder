# frozen_string_literal: true

json.cache! ["v7", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle.user, vehicle, vehicle.launch_port_location&.link_cache_key, vehicle.model&.manufacturer, (vehicle.effective_plaque_style if vehicle.dedication.present?), I18n.locale] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)
end
