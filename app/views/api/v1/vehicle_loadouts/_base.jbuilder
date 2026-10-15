# frozen_string_literal: true

json.id vehicle_loadout.id
json.name vehicle_loadout.name
json.active vehicle_loadout.active
json.kind vehicle_loadout.kind
# Left out rather than null on a fleetyards loadout, which links nowhere.
json.url vehicle_loadout.url if vehicle_loadout.url.present?
json.url_source vehicle_loadout.url_source if vehicle_loadout.url_source.present?
json.items vehicle_loadout.items do |item|
  json.slot item.slot
  json.model_module_id item.model_module_id
end

json.partial! "api/shared/dates", record: vehicle_loadout
