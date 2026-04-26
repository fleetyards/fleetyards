# frozen_string_literal: true

class AddQualityToFleetInventoryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :fleet_inventory_items, :quality, :integer, default: 0
  end
end
