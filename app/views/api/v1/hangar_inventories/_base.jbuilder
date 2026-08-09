# frozen_string_literal: true

json.id hangar_inventory.id
json.name hangar_inventory.name
json.slug hangar_inventory.slug
json.description hangar_inventory.description
json.location hangar_inventory.location
json.item_count hangar_inventory.hangar_inventory_items.size

stock = hangar_inventory.current_stock
json.total_scu stock.select { |s| s.unit == "scu" }.sum(&:net_quantity).to_f
json.total_units stock.select { |s| s.unit == "units" }.sum(&:net_quantity).to_f

if hangar_inventory.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: hangar_inventory, attr: :image
  end
else
  json.image nil
end

json.partial! "api/shared/dates", record: hangar_inventory
