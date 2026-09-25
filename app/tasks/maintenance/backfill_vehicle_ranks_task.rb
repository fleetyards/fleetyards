# frozen_string_literal: true

module Maintenance
  # Ranks the vehicles of every owner who has unranked ones; see
  # `Vehicle.rank_unranked!` for the order and the spacing.
  #
  # A task rather than a data migration: it writes every vehicle there is, and
  # `bin/deploy-release` runs `data:migrate` inside the Kamal pre-deploy hook, so
  # as a migration it would hold up the deploy behind it and repeat on each of
  # the hook's retries. And it has to be able to run twice -- the old release
  # keeps creating unranked vehicles until the new one is up -- which a data
  # migration, run once, cannot.
  #
  # Re-runnable and additive: an owner whose vehicles all have ranks is not in
  # the collection, and a ranked vehicle is never moved. No `dry_run` attribute
  # on purpose -- one that defaults to true makes a console run roll back
  # silently while still reporting "succeeded".
  class BackfillVehicleRanksTask < MaintenanceTasks::Task
    def collection
      User.where(id: Vehicle.where(rank: nil).where.not(user_id: nil).select(:user_id))
    end

    def count
      collection.count
    end

    def process(user)
      Vehicle.rank_unranked!(user.id)
    end
  end
end
