# frozen_string_literal: true

item_slugs = InventoryLedgerEntry.item_slugs(@stock)

json.array! @stock, partial: "api/v1/shared/stock_position", as: :position, item_slugs:
