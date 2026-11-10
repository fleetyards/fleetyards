# frozen_string_literal: true

json.cache! ["v17", vehicle.model, vehicle.model&.facts, vehicle.model&.stock_loadout_stat, ::ScData::Source.current, Manufacturer.artwork_version, vehicle.user, vehicle, vehicle.fitted_loadout_stat(public_only: true), vehicle.launch_port_location&.link_cache_key, vehicle.model&.manufacturer, (vehicle.effective_plaque_style if vehicle.dedication.present?), I18n.locale] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)
end
