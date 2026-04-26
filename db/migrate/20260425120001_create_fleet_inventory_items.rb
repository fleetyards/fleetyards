# frozen_string_literal: true

class CreateFleetInventoryItems < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_inventory_items, id: :uuid do |t|
      t.references :fleet_inventory, type: :uuid, null: false, foreign_key: true
      t.string :item_type
      t.uuid :item_id
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.decimal :quantity, precision: 15, scale: 2, null: false, default: 0
      t.integer :unit, null: false, default: 0
      t.text :notes
      t.uuid :added_by
      t.timestamps
    end

    add_index :fleet_inventory_items, [:fleet_inventory_id, :item_type, :item_id],
      unique: true, where: "item_type IS NOT NULL",
      name: "idx_fleet_inventory_items_unique_linked"
    add_foreign_key :fleet_inventory_items, :users, column: :added_by
  end
end
