# frozen_string_literal: true

json.cache! ["v4", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle, I18n.locale] do
  json.partial!("api/v1/vehicles/base", vehicle:)
end
