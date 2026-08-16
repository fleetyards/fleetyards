# frozen_string_literal: true

json.items do
  json.array! @hangar_inventory_items, partial: "api/v1/hangar_inventory_items/hangar_inventory_item", as: :hangar_inventory_item
end
json.partial! "api/shared/meta", result: @hangar_inventory_items
