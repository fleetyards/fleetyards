# frozen_string_literal: true

json.items do
  json.array! @hangar_inventories, partial: "api/v1/hangar_inventories/hangar_inventory", as: :hangar_inventory
end
json.partial! "api/shared/meta", result: @hangar_inventories
