# frozen_string_literal: true

json.cache! ["v1", model_hardpoint_loadout, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/model_hardpoint_loadouts/base", model_hardpoint_loadout:)
end
