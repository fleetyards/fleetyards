# frozen_string_literal: true

class AddBundledVehiclesToImports < ActiveRecord::Migration[8.1]
  # A hangar sync creates the snub craft a ship comes with, the same way adding
  # a ship by hand does. Users who track those separately -- or not at all --
  # had no way to stop a sync putting them back, so the run now carries the
  # choice. Defaults to on, which is what every sync did before.
  def change
    add_column :imports, :add_bundled_vehicles, :boolean, default: true, null: false
  end
end
