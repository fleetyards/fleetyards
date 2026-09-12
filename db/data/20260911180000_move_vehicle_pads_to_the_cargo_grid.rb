# frozen_string_literal: true

# `vehiclepad` never expressed what it was meant to. It was supposed to separate
# a berth on the cargo grid from a dedicated vehicle bay, and it did not: the
# Carrack's dedicated garage and the Hammerhead's cargo lift were both reachable
# under either value, and the dimensions matched too.
#
# What did carry the distinction was the name. All five surviving `vehiclepad`
# rows are called "Cargo" or "Cargolift" -- Valkyrie, Hammerhead, and the three
# Hercules -- so every one of them is a cargo grid, and this moves them.
#
# The mixed `garage` rows are not touched. Six of the twelve are named Cargohold
# or Cargobay and six are dedicated bays, and only somebody who knows the ships
# can say which is which. That is a curation pass, not a migration.
class MoveVehiclePadsToTheCargoGrid < ActiveRecord::Migration[8.1]
  def up
    moved = Dock.where(dock_type: :vehiclepad).update_all(dock_type: Dock.dock_types[:cargogrid])

    say("moved #{moved} vehicle pad(s) to the cargo grid")
  end

  # Not reversible, and no heuristic makes it so. Nothing on a dock records
  # which type it used to carry, and the editor offers `cargogrid` now -- so
  # after this runs, a row curated by hand is indistinguishable from one this
  # migration moved. Scoping the reverse to the names the five happened to have
  # was the first attempt and is no better: an admin can name a new one "Cargo"
  # too.
  #
  # Turning somebody's curation back into a legacy type is worse than refusing,
  # and the forward direction is five rows. Undo it by hand if it ever needs
  # undoing.
  def down
    raise ActiveRecord::IrreversibleMigration,
      "nothing records which docks were vehicle pads before this ran, and the " \
      "admin can create a cargo grid now -- reverting would take hand-curated " \
      "rows with it. Set the types back by hand if this really has to go."
  end
end
