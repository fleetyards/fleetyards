# frozen_string_literal: true

json.items do
  json.array! @inventories, partial: "admin/api/v1/fleet_inventories/fleet_inventory", as: :inventory
end
json.partial! "api/shared/meta", result: @inventories
