# frozen_string_literal: true

# What a contract asks for, one row per stock position.
#
# The identity columns are the ledger's own -- `InventoryLedgerEntry::
# POSITION_COLUMNS` is exactly `name`, `category`, `unit` -- because that triple
# is what decides two entries are the same position, and a line has to match
# deposits by the same rule the deposits were grouped by. `item_type`/`item_id`
# is for the icon and the link only: the reference is optional on an entry, so
# matching on it would fail to count a hand-typed deposit of the right goods.
class CreateFleetContractItems < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_contract_items, id: :uuid do |t|
      t.references :fleet_contract, type: :uuid, null: false,
        foreign_key: {to_table: :fleet_contracts, on_delete: :cascade}

      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.integer :unit, null: false, default: 0

      t.string :item_type
      t.uuid :item_id

      t.decimal :quantity, precision: 15, scale: 2, null: false, default: 0

      # Only a crafting contract sets one. 0..1000, the range
      # InventoryLedgerEntry already validates quality against.
      t.integer :min_quality

      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :fleet_contract_items, [:fleet_contract_id, :position]
    add_index :fleet_contract_items, [:item_type, :item_id]

    add_check_constraint :fleet_contract_items, "quantity > 0",
      name: "fleet_contract_items_quantity_positive"

    add_check_constraint :fleet_contract_items,
      "min_quality IS NULL OR (min_quality >= 0 AND min_quality <= 1000)",
      name: "fleet_contract_items_min_quality_range"
  end
end
