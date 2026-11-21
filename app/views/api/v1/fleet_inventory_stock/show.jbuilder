# frozen_string_literal: true

json.partial! "api/v1/shared/stock_item", stock_item: @stock_item

# Read as the response is rendered, so a rename that merged positions or a
# hand-over that just moved stock is already in it.
json.partial! "api/v1/shared/stock_holders",
  shares: InventoryHolderBalances.new(@inventory.fleet_inventory_items).for_position(@stock_item.position_id)
