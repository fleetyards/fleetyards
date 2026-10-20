# frozen_string_literal: true

json.id vehicle_loadout.id
json.name vehicle_loadout.name
json.active vehicle_loadout.active
json.public vehicle_loadout.public
json.kind vehicle_loadout.kind
# Left out rather than null on a fleetyards loadout, which links nowhere.
json.url vehicle_loadout.url if vehicle_loadout.url.present?
json.url_source vehicle_loadout.url_source if vehicle_loadout.url_source.present?
json.items vehicle_loadout.items do |item|
  json.slot_path item.slot_path
  json.item_type item.item_type
  json.item_id item.item_id if item.item_id
  if item.blueprint
    json.crafted do
      json.blueprint_id item.blueprint_id
      json.blueprint_slug item.blueprint.slug
      json.qualities item.crafted_qualities.sort_by { |position, _| position.to_i } do |position, quality|
        json.position position.to_i
        json.quality quality
      end
    end
  end
end

json.power_presets vehicle_loadout.power_presets do |preset|
  json.name preset["name"]
  VehicleLoadout::POWER_MODES.each do |mode|
    json.set! mode, Array(preset[mode]) do |override|
      json.port_path override["port_path"]
      json.pips override["pips"]
    end
  end
end

json.partial! "api/shared/dates", record: vehicle_loadout
