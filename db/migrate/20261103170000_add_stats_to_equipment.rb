class AddStatsToEquipment < ActiveRecord::Migration[8.1]
  def change
    %i[equipment equipment_builds].each do |table|
      add_column table, :stats, :jsonb
      add_column table, :alpha_damage, :decimal, precision: 15, scale: 2
      add_column table, :dps, :decimal, precision: 15, scale: 2
    end
  end
end
