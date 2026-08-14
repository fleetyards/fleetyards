# frozen_string_literal: true

json.slug InventoryStockItem.slug_for(name: position.name, category: position.category, unit: position.unit)
json.name position.name
json.category position.category
json.unit position.unit
if position.respond_to?(:quality_min)
  json.quality_min position.quality_min
  json.quality_max position.quality_max
else
  json.quality position.quality
end
json.net_quantity position.net_quantity.to_f

if position.respond_to?(:inventory_name) && position.inventory_name.present?
  json.inventory do
    json.name position.inventory_name
    json.slug position.inventory_slug
  end
end
