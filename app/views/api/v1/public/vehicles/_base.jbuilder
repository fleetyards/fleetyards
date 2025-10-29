# frozen_string_literal: true

json.id vehicle.id
if vehicle.name_visible?
  json.name vehicle.name
end
if vehicle.name_visible?
  json.slug vehicle.slug
end
if vehicle.name_visible?
  json.serial vehicle.serial
end
json.loaner vehicle.loaner
json.model do
  json.partial! "api/v1/models/base", model: vehicle.model if vehicle.model.present?
end
if vehicle.model_paint.present?
  json.paint do
    json.partial! "api/v1/model_paints/base", model_paint: vehicle.model_paint if vehicle.model_paint.present?
  end
end
json.model_module_ids vehicle.model_module_ids
json.model_upgrade_ids vehicle.model_upgrade_ids

unless vehicle.user.hide_owner?
  json.username vehicle.user.username
  json.user_avatar vehicle.user.avatar.small.url
  json.user_rsi_handle vehicle.user.rsi_handle
end

json.hangar_group_ids vehicle.public_hangar_group_ids
json.hangar_groups do
  json.array! vehicle.public_hangar_groups, partial: "api/v1/public/hangar_groups/base", as: :group
end
if vehicle.module_package.present?
  json.module_package do
    json.partial! "api/v1/model_module_packages/base", module_package: vehicle.module_package if vehicle.module_package.present?
  end
end
json.partial! "api/shared/dates", record: vehicle
