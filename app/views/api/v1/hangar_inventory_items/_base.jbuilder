# frozen_string_literal: true

json.id hangar_inventory_item.id
json.name hangar_inventory_item.name
json.category hangar_inventory_item.category
json.quantity hangar_inventory_item.quantity.to_f
json.unit hangar_inventory_item.unit
json.entry_type hangar_inventory_item.entry_type
json.quality hangar_inventory_item.quality
json.notes hangar_inventory_item.notes

json.image do
  json.partial! "api/v1/shared/inventory_image", entry: hangar_inventory_item
end

if hangar_inventory_item.hangar_inventory.present?
  json.inventory do
    json.name hangar_inventory_item.hangar_inventory.name
    json.slug hangar_inventory_item.hangar_inventory.slug
  end
end

if hangar_inventory_item.item.present?
  json.item do
    json.id hangar_inventory_item.item_id
    json.type hangar_inventory_item.item_type
    json.name hangar_inventory_item.item.name
    json.slug hangar_inventory_item.item.slug
  end
else
  json.item nil
end

json.partial! "api/shared/dates", record: hangar_inventory_item
