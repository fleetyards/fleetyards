# frozen_string_literal: true

class AddHolderToFleetInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_inventory_items, :holder_id, :uuid
    add_foreign_key :fleet_inventory_items, :users, column: :holder_id, on_delete: :nullify
    add_index :fleet_inventory_items, :holder_id
  end
end
