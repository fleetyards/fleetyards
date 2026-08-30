# frozen_string_literal: true

json.items do
  json.array! @items, partial: "admin/api/v1/fleet_inventory_items/fleet_inventory_item", as: :item
end
json.partial! "api/shared/meta", result: @items
