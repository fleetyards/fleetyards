# frozen_string_literal: true

json.cache! ["v1", vehicle_loadout] do
  json.partial!("api/v1/vehicle_loadouts/base", vehicle_loadout:)
end
