# frozen_string_literal: true

class AddInventoryToEquipment < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :inventory, :jsonb
    add_column :equipment_builds, :inventory, :jsonb
  end
end
