# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name_visible? ? vehicle.name : vehicle.model.name
json.purchased vehicle.purchased
json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.model do
  json.partial! 'api/v1/models/minimal', model: vehicle.model if vehicle.model.present?
end
json.model nil if vehicle.model.blank?
json.hangar_group_ids vehicle.hangar_group_ids
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids
json.partial! 'api/shared/dates', record: vehicle
