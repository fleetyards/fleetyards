# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name_visible? ? vehicle.name : nil
json.model do
  json.partial! 'api/v1/models/minimal', model: vehicle.model if vehicle.model.present?
end
json.model nil if vehicle.model.blank?
json.paint do
  json.partial! 'api/v1/model_paints/minimal', model_paint: vehicle.model_paint if vehicle.model_paint.present?
end
json.paint nil if vehicle.model_paint.blank?
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids
json.username vehicle.user.username
json.partial! 'api/shared/dates', record: vehicle
