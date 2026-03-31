# frozen_string_literal: true

json.items do
  json.array! @model_hardpoint_loadouts, partial: "admin/api/v1/model_hardpoint_loadouts/model_hardpoint_loadout", as: :model_hardpoint_loadout
end

json.partial! "api/shared/meta", result: @model_hardpoint_loadouts
