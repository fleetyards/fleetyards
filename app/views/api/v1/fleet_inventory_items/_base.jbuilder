# frozen_string_literal: true

json.id fleet_inventory_item.id
json.name fleet_inventory_item.name
json.position_id fleet_inventory_item.position_id
# The position's own slug, which carries a disambiguating suffix where two names
# compete for one address. Derived as a fallback only for a row the previous
# release inserted before the backfill reached it.
json.stock_slug fleet_inventory_item.position&.slug ||
  InventoryStockItem.slug_for(name: fleet_inventory_item.name, category: fleet_inventory_item.category, unit: fleet_inventory_item.unit)
json.category fleet_inventory_item.category
json.quantity fleet_inventory_item.quantity.to_f
json.unit fleet_inventory_item.unit
json.entry_type fleet_inventory_item.entry_type
json.quality fleet_inventory_item.quality
json.notes fleet_inventory_item.notes

# The transfer that wrote this entry, if one did. A deposit somebody typed and
# a deposit that arrived from another inventory are the same row otherwise, and
# the ledger is where you go to find out which.
json.transfer_id fleet_inventory_item.inventory_transfer_id

# Where the goods came from, or went to. A marker alone says an entry was not
# typed by hand; this says what the ledger is actually being asked.
if fleet_inventory_item.inventory_transfer.present?
  json.transfer do
    inventory, party = fleet_inventory_item.inventory_transfer.counterpart_for(fleet_inventory_item.inventory)

    json.id fleet_inventory_item.inventory_transfer_id
    json.direction fleet_inventory_item.deposit? ? "in" : "out"
    json.counterparty do
      json.partial! "api/v1/shared/transfer_party", party: party
    end
    json.inventory do
      if inventory.blank?
        json.null!
      else
        json.name inventory.name
        json.kind inventory.is_a?(::FleetInventory) ? "fleet" : "user"
      end
    end
  end
else
  json.transfer nil
end

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
