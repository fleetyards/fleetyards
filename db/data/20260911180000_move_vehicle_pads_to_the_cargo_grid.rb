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

  def down
    Dock.where(dock_type: :cargogrid).update_all(dock_type: Dock.dock_types[:vehiclepad])
  end
end
