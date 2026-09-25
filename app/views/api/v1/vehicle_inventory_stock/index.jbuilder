# frozen_string_literal: true

linked_items = InventoryLedgerEntry.linked_items(@stock)

json.array! @stock, partial: "api/v1/shared/stock_position", as: :position, linked_items:
