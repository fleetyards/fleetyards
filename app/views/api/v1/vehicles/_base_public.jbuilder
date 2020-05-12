# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name_visible? ? vehicle.name : nil
json.model do
  json.partial! 'api/v1/models/minimal', model: vehicle.model if vehicle.model.present?
end
json.model nil if vehicle.model.blank?
json.skin do
  json.partial! 'api/v1/model_skins/minimal', model_skin: vehicle.model_skin if vehicle.model_skin.present?
end
json.skin nil if vehicle.model_skin.blank?
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids
json.partial! 'api/shared/dates', record: vehicle
