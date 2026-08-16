# frozen_string_literal: true

json.id fleet_inventory_item.id
json.name fleet_inventory_item.name
json.stock_slug InventoryStockItem.slug_for(name: fleet_inventory_item.name, category: fleet_inventory_item.category, unit: fleet_inventory_item.unit)
json.category fleet_inventory_item.category
json.quantity fleet_inventory_item.quantity.to_f
json.unit fleet_inventory_item.unit
json.entry_type fleet_inventory_item.entry_type
json.quality fleet_inventory_item.quality
json.notes fleet_inventory_item.notes

json.image do
  json.partial! "api/v1/shared/inventory_image", entry: fleet_inventory_item
end

if fleet_inventory_item.fleet_inventory.present?
  json.inventory do
    json.name fleet_inventory_item.fleet_inventory.name
    json.slug fleet_inventory_item.fleet_inventory.slug
  end
end

if fleet_inventory_item.item.present?
  json.item do
    json.id fleet_inventory_item.item_id
    json.type fleet_inventory_item.item_type
    json.name fleet_inventory_item.item.name
    json.slug fleet_inventory_item.item.slug
    json.available fleet_inventory_item.item_available?
  end
else
  json.item nil
end

if fleet_inventory_item.member.present?
  json.member do
    json.id fleet_inventory_item.member.id
    json.username fleet_inventory_item.member.username
  end
else
  json.member nil
end

if fleet_inventory_item.added_by_user.present?
  json.added_by do
    json.id fleet_inventory_item.added_by_user.id
    json.username fleet_inventory_item.added_by_user.username
  end
else
  json.added_by nil
end

json.partial! "api/shared/dates", record: fleet_inventory_item
