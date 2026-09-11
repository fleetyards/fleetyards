# frozen_string_literal: true

module Maintenance
  # Drops the rows the hangar's bulk deletions left pointing at vehicles that no
  # longer exist.
  #
  # `wishlists#destroy`, `vehicles#destroy_bulk` and `vehicles#destroy_all_ingame`
  # go around `Vehicle#destroy` -- a wishlist wipe is a few thousand rows and
  # every callback on the way out queues a job -- and cleared a hand-maintained
  # list of child tables that only ever covered `vehicle_upgrades` and
  # `vehicle_modules`. They share `Vehicle.delete_with_dependents` now, so nothing
  # new is stranded. This clears what is already on disk:
  #
  #     13,437 vehicles -- 13,436 loaners and one bundled snub craft
  #    195,457 fleet_vehicles of 1,063,946
  #     18,278 task_forces of 96,229
  #
  # Only `vehicle_loadouts` has a foreign key, which is why that one table turned
  # a silent orphan into an `ActiveRecord::InvalidForeignKey` and surfaced the
  # rest. Nothing constrains the other three, so they accumulated unnoticed.
  #
  # The vehicles are not bookkeeping: 4,769 of them are visible, spread over
  # 1,135 users, so this takes ships out of hangars people are looking at. Each
  # is a loaner for a pledge its owner deleted, which is the case
  # `RepairLoanerFlagsTask` deliberately left alone -- "destroying it is a
  # decision for whoever finds out how it got orphaned". This is that decision.
  #
  # A maintenance task rather than a data migration, for the reason
  # `DropChangelessVersionsTask` records: it destroys rows and cannot be undone,
  # and `data:migrate` runs unattended inside the Kamal pre-deploy hook.
  #
  # It clears roughly a row in five from `fleet_vehicles` and `task_forces`, so
  # follow it with `VACUUM ANALYZE fleet_vehicles, task_forces` for the planner's
  # sake rather than waiting for autovacuum.
  class DropVehicleOrphansTask < MaintenanceTasks::Task
    no_collection

    # A vehicle batch is several statements and a `hidden` regroup per pass, so
    # it is the smaller one.
    VEHICLE_BATCH_SIZE = 1_000
    JOIN_BATCH_SIZE = 5_000

    # Left on by default so an accidental run reports instead of destroying.
    # `MaintenanceTasks::Runner.run` with no `arguments:` takes this default and
    # still finishes as "succeeded", so a real run has to pass `dry_run => "0"`.
    attribute :dry_run, :boolean, default: true

    # `vehicle_id` is nowhere null in any of the three, so "missing" and "dangling"
    # are the same set -- but `where.missing` states the one that matters, and a
    # null arriving later is not this task's row to delete.
    def self.orphaned_vehicles
      Vehicle.where.not(vehicle_id: nil).where.missing(:parent_vehicle)
    end

    def self.orphaned_fleet_vehicles
      FleetVehicle.where.missing(:vehicle)
    end

    def self.orphaned_task_forces
      TaskForce.where.missing(:vehicle)
    end

    def process
      dry_run ? report_plan : apply
    end

    # Vehicles first: an orphan carries `fleet_vehicles` and `task_forces` of its
    # own, which are not orphaned while it stands, and
    # `Vehicle.delete_with_dependents` takes them with it. Running the join tables
    # first would leave those behind for a second run to find.
    private def apply
      vehicles = drop_in_batches(self.class.orphaned_vehicles, size: VEHICLE_BATCH_SIZE) do |ids|
        Vehicle.delete_with_dependents(ids)
      end

      fleet_vehicles = drop_in_batches(self.class.orphaned_fleet_vehicles, size: JOIN_BATCH_SIZE) do |ids|
        FleetVehicle.where(id: ids).delete_all
      end

      task_forces = drop_in_batches(self.class.orphaned_task_forces, size: JOIN_BATCH_SIZE) do |ids|
        TaskForce.where(id: ids).delete_all
      end

      log "vehicles: deleted #{vehicles}"
      log "fleet_vehicles: deleted #{fleet_vehicles}"
      log "task_forces: deleted #{task_forces}"
    end

    # Re-reads the scope each pass rather than iterating it once: every row it
    # selects on is a row it deletes, so there is no cursor to carry and nothing
    # for a resumed run to skip past.
    private def drop_in_batches(scope, size:)
      deleted = 0

      while (ids = scope.limit(size).pluck(:id)).any?
        deleted += yield(ids)
      end

      deleted
    end

    # The join-table counts are reported in two parts, because that is how the
    # apply removes them: the vehicles take their own rows with them, so the
    # orphaned count alone does not add up to what a run reports deleting.
    private def report_plan
      vehicles = self.class.orphaned_vehicles

      log "vehicles: #{vehicles.count} orphaned of #{Vehicle.count}, " \
        "#{vehicles.visible.count} visible, across #{vehicles.distinct.count(:user_id)} users"
      log "fleet_vehicles: #{self.class.orphaned_fleet_vehicles.count} orphaned of #{FleetVehicle.count}, " \
        "plus #{FleetVehicle.where(vehicle_id: vehicles.select(:id)).count} carried by those vehicles"
      log "task_forces: #{self.class.orphaned_task_forces.count} orphaned of #{TaskForce.count}, " \
        "plus #{TaskForce.where(vehicle_id: vehicles.select(:id)).count} carried by those vehicles"
      log "dry run -- nothing was deleted"
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
