# frozen_string_literal: true

json.id fleet_inventory.id
json.name fleet_inventory.name
json.slug fleet_inventory.slug
json.description fleet_inventory.description
json.visibility fleet_inventory.visibility
json.location fleet_inventory.location
json.item_count fleet_inventory.fleet_inventory_items.size

stock = fleet_inventory.current_stock
json.total_scu stock.select { |s| s.unit == "scu" }.sum(&:net_quantity).to_f
json.total_units stock.select { |s| s.unit == "units" }.sum(&:net_quantity).to_f

if fleet_inventory.manager.present?
  json.manager do
    json.id fleet_inventory.manager.id
    json.username fleet_inventory.manager.username
  end
else
  json.manager nil
end

if fleet_inventory.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: fleet_inventory, attr: :image
  end
else
  json.image nil
end

json.partial! "api/shared/dates", record: fleet_inventory
