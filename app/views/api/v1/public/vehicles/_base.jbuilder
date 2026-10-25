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
# Fleet lists render this partial for vehicles that are not public too. A
# wishlist ship's plaque stays private: a shared plaque opens the public hangar,
# which has no wishlist ships.
if vehicle.public? && !vehicle.wanted? && !vehicle.loaner?
  json.partial!("api/v1/vehicles/dedication_plaque", vehicle:)
end
json.model do
  json.partial! "api/v1/models/model", model: vehicle.model if vehicle.model.present?
end
json.model_module_ids vehicle.model_module_ids
json.cargo vehicle.fitted_cargo(public_only: true).to_f
json.cargo_with_modules vehicle.cargo_with_modules(public_only: true)&.to_f
json.partial!("api/v1/vehicles/weapons", stat: vehicle.fitted_loadout_stat(public_only: true))
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

json.partial!("api/v1/vehicles/image", vehicle:)

active_loadout = vehicle.vehicle_loadouts.find { |loadout| loadout.active? && loadout.public? }
json.active_loadout do
  json.partial! "api/v1/vehicle_loadouts/base", vehicle_loadout: active_loadout if active_loadout.present?
end

json.partial! "api/shared/dates", record: vehicle
