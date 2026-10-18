# frozen_string_literal: true

# A ship's active loadout showed on its public plaque before loadouts had a
# visibility of their own, so the active ones stay public.
class MakeActiveVehicleLoadoutsPublic < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE vehicle_loadouts SET public = TRUE WHERE active = TRUE
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
