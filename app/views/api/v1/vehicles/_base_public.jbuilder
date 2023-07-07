# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name_visible? ? vehicle.name : nil
json.slug vehicle.name_visible? ? vehicle.slug : nil
json.serial vehicle.name_visible? ? vehicle.serial : nil
json.loaner vehicle.loaner
json.model do
  json.partial! "api/v1/models/minimal", model: vehicle.model if vehicle.model.present?
end
json.paint do
  json.partial! "api/v1/model_paints/minimal", model_paint: vehicle.model_paint if vehicle.model_paint.present?
end
json.paint nil if vehicle.model_paint.blank?
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids
json.username vehicle.user.hide_owner? ? nil : vehicle.user.username
json.user_avatar vehicle.user.hide_owner? ? nil : vehicle.user.avatar.small.url
json.hangar_group_ids vehicle.public_hangar_group_ids
json.hangar_groups do
  json.array! vehicle.public_hangar_groups, partial: "api/v1/hangar_groups/base", as: :group
end
json.module_package do
  json.partial! "api/v1/model_module_packages/minimal", module_package: vehicle.module_package if vehicle.module_package.present?
end
json.module_package nil if vehicle.module_package.blank?
