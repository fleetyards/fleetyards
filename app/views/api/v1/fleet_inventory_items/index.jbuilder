# frozen_string_literal: true

json.items do
  json.array! @fleet_inventory_items, partial: "api/v1/fleet_inventory_items/fleet_inventory_item", as: :fleet_inventory_item
end
json.partial! "api/shared/meta", result: @fleet_inventory_items
