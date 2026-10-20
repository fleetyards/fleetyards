# frozen_string_literal: true

class AddPowerPresetsToVehicleLoadouts < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicle_loadouts, :power_presets, :jsonb, default: [], null: false
  end
end
