class AddArmorStatsToEquipment < ActiveRecord::Migration[8.1]
  def change
    # The rest of the armour spec block already had columns waiting for it --
    # damage_reduction, temperature_rating and the two compatibility enums were
    # sketched for exactly this data. These three had none.
    add_column :equipment, :radiation_protection, :decimal, precision: 15, scale: 2
    add_column :equipment, :radiation_scrub_rate, :decimal, precision: 15, scale: 2
    add_column :equipment, :g_force_tolerance, :decimal, precision: 15, scale: 2

    add_index :equipment, :slot
  end
end
