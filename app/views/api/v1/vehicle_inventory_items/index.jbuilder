# frozen_string_literal: true

json.items do
  json.array! @inventory_items, partial: "api/v1/vehicle_inventory_items/vehicle_inventory_item", as: :inventory_item
end
json.partial! "api/shared/meta", result: @inventory_items
