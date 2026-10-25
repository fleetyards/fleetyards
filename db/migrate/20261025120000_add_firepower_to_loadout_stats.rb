# frozen_string_literal: true

class AddFirepowerToLoadoutStats < ActiveRecord::Migration[8.1]
  def change
    add_column :loadout_stats, :alpha, :float
    add_column :loadout_stats, :burst_dps, :float
    add_column :loadout_stats, :sustained_dps_min, :float
    add_column :loadout_stats, :sustained_dps_max, :float
    add_column :loadout_stats, :formula_version, :integer
  end
end
