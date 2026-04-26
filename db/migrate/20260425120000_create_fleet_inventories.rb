# frozen_string_literal: true

class CreateFleetInventories < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_inventories, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.uuid :managed_by
      t.integer :visibility, null: false, default: 0
      t.timestamps
    end

    add_index :fleet_inventories, [:fleet_id, :slug], unique: true
    add_index :fleet_inventories, "fleet_id, LOWER(name)", unique: true,
      name: "index_fleet_inventories_on_fleet_id_and_lower_name"
    add_index :fleet_inventories, [:fleet_id, :managed_by]
    add_foreign_key :fleet_inventories, :users, column: :managed_by
  end
end
