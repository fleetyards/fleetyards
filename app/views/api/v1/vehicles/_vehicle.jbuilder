# frozen_string_literal: true

json.cache! ["v13", vehicle.model, vehicle.model&.facts, ::ScData::Source.current, Manufacturer.artwork_version, vehicle, vehicle.linked_location&.link_cache_key, vehicle.launch_port_location&.link_cache_key, vehicle.model&.manufacturer, (vehicle.effective_plaque_style if vehicle.dedication.present?), I18n.locale] do
  json.partial!("api/v1/vehicles/base", vehicle:)
end
