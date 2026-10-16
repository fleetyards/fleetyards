# frozen_string_literal: true

# The furniture a ship's rooms hold: the berths its crew sleeps in, the slots of
# its weapon racks and its armour lockers. Filled from the game files on the
# next load; an interior that predates its ship's rework leaves them empty.
class AddInteriorToModels < ActiveRecord::Migration[8.1]
  def change
    %i[models model_builds].each do |table|
      add_column table, :beds, :integer
      add_column table, :weapon_racks, :string
      add_column table, :lockers, :integer
    end
  end
end
