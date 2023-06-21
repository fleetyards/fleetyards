class ChangeDefaultOfBooleans < ActiveRecord::Migration[7.0]
  def change
    change_column_default(:shops, :refinery_terminal, false)
    change_column_default(:stations, :refinery, false)
    change_column_default(:stations, :cargo_hub, false)
    change_column_default(:celestial_objects, :habitable, false)
    change_column_default(:celestial_objects, :fairchanceact, false)
    change_column_default(:roadmap_items, :released, false)
    change_column_default(:roadmap_items, :active, false)
  end
end
