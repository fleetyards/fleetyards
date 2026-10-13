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
json.public_log_entries_count vehicle.public_log_entries_count
# Fleet lists render this partial for vehicles that are not public too, and the
# public wishlist for ships the owner cannot give a plaque.
if vehicle.public? && !vehicle.wanted? && !vehicle.loaner?
  json.partial!("api/v1/vehicles/dedication_plaque", vehicle:)
end
json.model do
  json.partial! "api/v1/models/model", model: vehicle.model if vehicle.model.present?
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
  json.user_display_name vehicle.user.display_name if vehicle.user.display_name.present?
  json.user_avatar(vehicle.user.avatar.attached? ? rails_representation_url(vehicle.user.avatar.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:small])) : nil)
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

if vehicle.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: vehicle, attr: :image
  end
end

if vehicle.model_image&.enabled? && vehicle.model_image.file.attached?
  json.model_image do
    json.partial! "api/v1/shared/file", record: vehicle.model_image, attr: :file
  end
end

active_loadout = vehicle.vehicle_loadouts.find(&:active?)
json.active_loadout do
  json.partial! "api/v1/vehicle_loadouts/base", vehicle_loadout: active_loadout if active_loadout.present?
end

json.partial! "api/shared/dates", record: vehicle
