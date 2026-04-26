# frozen_string_literal: true

class AddEntryTypeToFleetInventoryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :fleet_inventory_items, :entry_type, :integer, null: false, default: 0

    remove_index :fleet_inventory_items,
      name: "idx_fleet_inventory_items_unique_linked",
      if_exists: true
  end
end
