# frozen_string_literal: true

json.id model_hardpoint_loadout.id
json.name model_hardpoint_loadout.name
json.model_hardpoint_id model_hardpoint_loadout.model_hardpoint_id

json.component do
  json.partial! "api/v1/components/base", component: model_hardpoint_loadout.component if model_hardpoint_loadout.component.present?
end
json.component nil if model_hardpoint_loadout.component.blank?

json.partial! "api/shared/dates", record: model_hardpoint_loadout
