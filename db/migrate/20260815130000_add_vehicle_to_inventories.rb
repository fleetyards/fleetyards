# frozen_string_literal: true

class AddVehicleToInventories < ActiveRecord::Migration[8.1]
  def change
    add_reference :inventories, :vehicle, type: :uuid, null: true, index: false,
      foreign_key: {on_delete: :nullify}

    add_index :inventories, :vehicle_id, unique: true, where: "vehicle_id IS NOT NULL"

    remove_index :inventories, column: [:holder_type, :holder_id, :slug], unique: true
    remove_index :inventories, column: "holder_type, holder_id, LOWER(name)", unique: true,
      name: "index_inventories_on_holder_and_lower_name"

    add_index :inventories, [:holder_type, :holder_id, :slug], unique: true,
      where: "vehicle_id IS NULL"
    add_index :inventories, "holder_type, holder_id, LOWER(name)", unique: true,
      where: "vehicle_id IS NULL",
      name: "index_inventories_on_holder_and_lower_name"
  end
end
