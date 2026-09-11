# frozen_string_literal: true

# 391 of the 419 rows in `docks` belong to nothing.
#
# They were station docks. A script created 384 of them in six minutes on
# 2021-09-04 and seven more in 2022 -- numbered pads per station, "01" through
# "04", "Vehiclepad 01", and "Ladingpad 01" with the N missing in all 34 of
# them, so the names came from a hand-kept source.
#
# They became unreachable in March 2025, when `20250304083059_cleanup_stations`
# dropped a dozen tables and with them `docks.station_id` -- the column, not the
# rows. That is what `belongs_to :model, optional: true` was for: a dock belonged
# either to a model or to a station.
#
# Nothing references them. `Model#docks` is the only association to this table
# and there is no foreign key into it. None of the 391 carries dimensions, so
# nothing measurable is lost; 28 remain, all on player-ownable models, and all
# 23 models with docks keep theirs.
#
# `model_id` deliberately stays nullable. `cargo_holds` is already polymorphic
# and six of its rows hang off a `ModelModule` -- the Galaxy's medic module
# carries a vehicle lift for an Ursa -- so a dock wants the same parent. See
# #4863.
class RemoveOrphanedDocks < ActiveRecord::Migration[8.1]
  def up
    Dock.where(model_id: nil).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
