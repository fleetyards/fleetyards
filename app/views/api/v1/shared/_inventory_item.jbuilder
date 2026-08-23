# frozen_string_literal: true

json.id inventory_item.id
json.name inventory_item.name
json.stock_slug InventoryStockItem.slug_for(name: inventory_item.name, category: inventory_item.category, unit: inventory_item.unit)
json.category inventory_item.category
json.quantity inventory_item.quantity.to_f
json.unit inventory_item.unit
json.entry_type inventory_item.entry_type
json.quality inventory_item.quality
json.notes inventory_item.notes

json.image do
  json.partial! "api/v1/shared/inventory_image", entry: inventory_item
end

if inventory_item.inventory.present?
  json.inventory do
    json.name inventory_item.inventory.name
    json.slug inventory_item.inventory.slug
  end
end

if inventory_item.item.present?
  json.item do
    json.id inventory_item.item_id
    json.type inventory_item.item_type
    json.name inventory_item.item.name
    json.slug inventory_item.item.slug
    json.available inventory_item.item_available?
  end
else
  json.item nil
end

json.partial! "api/shared/dates", record: inventory_item
