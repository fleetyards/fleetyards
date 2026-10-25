# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name
json.slug vehicle.slug
json.serial vehicle.serial
json.wanted vehicle.wanted
json.hidden_by_user vehicle.hidden_by_user
json.bought_via vehicle.bought_via
json.bought_via_label vehicle.bought_via_label
json.loaner vehicle.loaner
json.bundled vehicle.bundled

bundled_parent = vehicle.parent_vehicle if vehicle.bundled?
json.bundled_parent do
  if bundled_parent&.model.present?
    json.id bundled_parent.id
    json.name bundled_parent.model.name
    json.slug bundled_parent.model.slug
    json.custom_name bundled_parent.name
  end
end
json.bundled_parent nil if bundled_parent&.model.blank?

json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.log_entries_public_by_default vehicle.log_entries_public_by_default
json.location vehicle.location
json.partial! "api/v1/locations/linked", key: :linked_location, location: vehicle.linked_location
json.alternative_names vehicle.alternative_names
json.partial!("api/v1/vehicles/dedication_plaque", vehicle:)

json.model do
  json.partial! "api/v1/models/model", model: vehicle.model
end

json.upgrade do
  json.partial! "api/v1/model_upgrades/base", model_upgrade: vehicle.model_upgrades.first if vehicle.model_upgrades.present?
end
json.upgrade nil if vehicle.model_upgrades.blank?

json.hangar_group_ids vehicle.hangar_group_ids
json.hangar_groups do
  json.array! vehicle.hangar_groups, partial: "api/v1/hangar_groups/base", as: :group
end

json.model_module_ids vehicle.model_module_ids
json.cargo vehicle.fitted_cargo.to_f
json.cargo_with_modules vehicle.cargo_with_modules&.to_f
json.partial!("api/v1/vehicles/weapons", stat: vehicle.fitted_loadout_stat)
json.model_upgrade_ids vehicle.model_upgrade_ids
json.model_paint_ids vehicle.model_paint_ids

json.module_package do
  json.partial! "api/v1/model_module_packages/base", module_package: vehicle.module_package if vehicle.module_package.present?
end
json.module_package nil if vehicle.module_package.blank?

json.partial!("api/v1/vehicles/image", vehicle:)
# For the editor alone: whether the picture is an upload, and what is picked.
json.image_uploaded vehicle.image.attached?
json.picture_type vehicle.picture_type
json.picture_id vehicle.picture_id

active_loadout = vehicle.vehicle_loadouts.find(&:active?)
json.active_loadout do
  json.partial! "api/v1/vehicle_loadouts/base", vehicle_loadout: active_loadout if active_loadout.present?
end

json.partial! "api/shared/dates", record: vehicle
