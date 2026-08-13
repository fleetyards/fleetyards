# frozen_string_literal: true

json.slug stock_item.slug
json.name stock_item.name
json.category stock_item.category
json.unit stock_item.unit
json.net_quantity stock_item.net_quantity.to_f
json.quality_min stock_item.quality_min
json.quality_max stock_item.quality_max
json.entries_count stock_item.entries_count

json.last_entry_at stock_item.last_entry_at

json.image do
  json.partial! "api/v1/shared/inventory_image", entry: stock_item.reference_entry
end

if stock_item.item.present?
  json.item do
    json.id stock_item.item.id
    json.type stock_item.reference_entry.item_type
    json.name stock_item.item.name
    json.slug stock_item.item.slug
  end
else
  json.item nil
end

if stock_item.inventory.present?
  json.inventory do
    json.name stock_item.inventory.name
    json.slug stock_item.inventory.slug
  end
end
