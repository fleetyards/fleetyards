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
  # What identified the five in the first place, and the only thing that can
  # identify them again afterwards. `up` moves every vehicle pad; every one of
  # them happens to be named this way, which is the evidence the move rests on.
  MOVED_NAMES = "Cargo%"

  def up
    moved = Dock.where(dock_type: :vehiclepad).update_all(dock_type: Dock.dock_types[:cargogrid])

    say("moved #{moved} vehicle pad(s) to the cargo grid")
  end

  def down
    # Not every cargo grid came from here. The admin can create one now, and
    # turning those back into vehicle pads would undo curation this migration
    # never touched -- so the reverse is scoped to the names that identified the
    # original five, and says what it left alone.
    scope = Dock.where(dock_type: :cargogrid)
    revertible = scope.where("docks.name ILIKE ?", MOVED_NAMES)

    kept = scope.count - revertible.count
    moved = revertible.update_all(dock_type: Dock.dock_types[:vehiclepad])

    say("moved #{moved} cargo grid(s) back to vehicle pads")
    say("left #{kept} cargo grid(s) alone: they were not named by this migration") if kept.positive?
  end
end
