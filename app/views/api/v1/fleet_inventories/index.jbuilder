# frozen_string_literal: true

json.items do
  json.array! @fleet_inventories, partial: "api/v1/fleet_inventories/fleet_inventory", as: :fleet_inventory
end
json.partial! "api/shared/meta", result: @fleet_inventories
