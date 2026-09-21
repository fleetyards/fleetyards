# frozen_string_literal: true

module Maintenance
  # Points hangar entries for in-game-only ships at the way they were actually
  # acquired.
  #
  # `bought_via` defaults to `pledge_store` and the RSI sync stamps every row it
  # creates the same way, so every entry predating a ship being flagged
  # `ingame_only` claims a purchase that was never possible. New saves are
  # corrected by `Vehicle#force_ingame_bought_via`; this is for the rows already
  # in the database, and for the ones a later flag turns into the same problem.
  #
  # Re-runnable, and no `dry_run` attribute -- one defaulting to true makes a
  # console run roll back silently while still reporting "succeeded".
  #
  # `update_columns` rather than `update!`: the value is the one the callback
  # would write anyway, and a full save on a hangar entry fans out to loaners,
  # bundled snub crafts and a fleet-vehicle job for a column none of them read.
  class RepairIngameOnlyBoughtViaTask < MaintenanceTasks::Task
    def collection
      Vehicle.where(model_id: Model.ingame_only.select(:id))
        .where.not(bought_via: :ingame)
    end

    def count
      collection.count
    end

    def process(vehicle)
      vehicle.update_columns(bought_via: Vehicle.bought_via[:ingame], updated_at: Time.zone.now)
    end
  end
end
