# frozen_string_literal: true

linked_items = InventoryLedgerEntry.linked_items(@stock)
crafted_blueprints = InventoryLedgerEntry.crafted_blueprints(@stock)

json.array! @stock, partial: "api/v1/shared/stock_position", as: :position, linked_items:, crafted_blueprints:
