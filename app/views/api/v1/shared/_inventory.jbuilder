# frozen_string_literal: true

json.id inventory.id
json.name inventory.name
json.slug inventory.slug
json.description inventory.description
json.location inventory.location
json.entries_count inventory.inventory_items.size

stock = inventory.persisted? ? inventory.current_stock : []
json.total_scu stock.select { |s| s.unit == "scu" }.sum(&:net_quantity).to_f
json.total_units stock.select { |s| s.unit == "units" }.sum(&:net_quantity).to_f

# Stock that has left on a transfer nobody has answered yet. It is gone from
# every total above -- the withdrawal is real -- so without this the goods
# simply disappear from the page that sent them.
json.in_transit_scu inventory.persisted? ? inventory.in_transit_totals[:scu] : 0.0
json.in_transit_units inventory.persisted? ? inventory.in_transit_totals[:units] : 0.0

volume = inventory.persisted? ? inventory.stock_volume : {total: 0.0, unmeasured: 0}
json.total_volume_scu volume[:total].round(4)
json.unmeasured_count volume[:unmeasured]

if inventory.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: inventory, attr: :image
  end
else
  json.image nil
end

if inventory.vehicle.present?
  json.vehicle do
    json.id inventory.vehicle.id
    json.name inventory.vehicle.display_name
    json.serial inventory.vehicle.serial
    json.model do
      json.name inventory.vehicle.model.name
      json.slug inventory.vehicle.model.slug
      json.cargo inventory.vehicle.model.cargo.to_f
      json.personal_inventory inventory.vehicle.model.personal_inventory.to_f
    end
  end
else
  json.vehicle nil
end

# A ship inventory only exists once something has been put in it, so the shape a
# GET hands back before that has no timestamps to report.
if inventory.persisted?
  json.partial! "api/shared/dates", record: inventory
else
  json.created_at nil
  json.updated_at nil
end
