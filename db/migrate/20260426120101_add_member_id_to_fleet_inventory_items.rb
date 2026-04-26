# frozen_string_literal: true

class AddMemberIdToFleetInventoryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :fleet_inventory_items, :member_id, :uuid
    add_foreign_key :fleet_inventory_items, :users, column: :member_id
    add_index :fleet_inventory_items, :member_id
  end
end
