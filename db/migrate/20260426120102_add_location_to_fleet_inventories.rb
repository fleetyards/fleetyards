# frozen_string_literal: true

class AddLocationToFleetInventories < ActiveRecord::Migration[7.2]
  def change
    add_column :fleet_inventories, :location, :string
  end
end
