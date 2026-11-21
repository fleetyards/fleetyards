# frozen_string_literal: true

class AddHolderToFleetInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_inventory_items, :holder_id, :uuid
    add_foreign_key :fleet_inventory_items, :users, column: :holder_id, on_delete: :nullify
    add_index :fleet_inventory_items, %i[fleet_inventory_position_id holder_id],
      name: "index_fleet_inventory_items_on_position_and_holder"
  end
end
