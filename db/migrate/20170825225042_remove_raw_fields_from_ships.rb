class RemoveRawFieldsFromShips < ActiveRecord::Migration[5.1]
  def up
    remove_column :ships, :propulsion_raw
    remove_column :ships, :avionics_raw
    remove_column :ships, :modular_raw
    remove_column :ships, :ordnance_raw
  end

  def down
    add_column :ships, :propulsion_raw, :text
    add_column :ships, :avionics_raw, :text
    add_column :ships, :modular_raw, :text
    add_column :ships, :ordnance_raw, :text
  end
end
