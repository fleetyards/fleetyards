# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name
json.serial vehicle.serial
json.purchased vehicle.purchased
json.loaner vehicle.loaner
json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.alternative_names vehicle.alternative_names
json.model do
  json.partial! "api/v1/models/minimal", model: vehicle.model if vehicle.model.present?
end
json.model nil if vehicle.model.blank?
json.paint do
  json.partial! "api/v1/model_paints/minimal", model_paint: vehicle.model_paint if vehicle.model_paint.present?
end
json.paint nil if vehicle.model_paint.blank?
json.upgrade do
  json.partial! "api/v1/model_upgrades/minimal", model_upgrade: vehicle.model_upgrades.first if vehicle.model_upgrades.present?
end
json.upgrade nil if vehicle.model_upgrades.blank?
json.hangar_group_ids vehicle.hangar_group_ids
json.hangar_groups do
  json.array! vehicle.hangar_groups, partial: "api/v1/vehicles/hangar_group", as: :hangar_group
end
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids
json.module_package do
  json.partial! "api/v1/model_module_packages/minimal", module_package: vehicle.module_package if vehicle.module_package.present?
end
json.module_package nil if vehicle.module_package.blank?
json.partial! "api/shared/dates", record: vehicle
