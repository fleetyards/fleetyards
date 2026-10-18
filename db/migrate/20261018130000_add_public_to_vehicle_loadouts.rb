# frozen_string_literal: true

class AddPublicToVehicleLoadouts < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicle_loadouts, :public, :boolean, default: false, null: false
  end
end
