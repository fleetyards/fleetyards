# frozen_string_literal: true

class AddSquadronsEnabledToFleets < ActiveRecord::Migration[8.1]
  def up
    add_column :fleets, :squadrons_enabled, :boolean, default: false, null: false

    # A fleet that already built squadrons keeps them switched on.
    execute <<~SQL.squish
      UPDATE fleets SET squadrons_enabled = TRUE
      WHERE EXISTS (SELECT 1 FROM fleet_squadrons WHERE fleet_squadrons.fleet_id = fleets.id)
    SQL
  end

  def down
    remove_column :fleets, :squadrons_enabled
  end
end
