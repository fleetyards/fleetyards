# frozen_string_literal: true

module Maintenance
  # Repairs the loaner rows two defects in `Vehicle#create_loaner` left behind.
  #
  # `wanted` used to be part of the existing-loaner lookup, so a ship moving
  # between hangar and wishlist missed its own loaners, created a second set and
  # stranded the first with a stale flag. A stranded row claiming `wanted: false`
  # under a wishlisted parent then passed `update_fleet_vehicle_for_all` and
  # reached the fleet.
  #
  # `hidden` was recomputed with a query that matched the row being recomputed,
  # so a visible loaner answered "a visible loaner already exists" about itself
  # and hid itself on the parent's next save. A user's only loaner disappeared
  # after any second save of its parent.
  #
  # Two more leftovers fed the drift after the first run. The stranded sets were
  # realigned but kept, so a parent still held several rows per loaner model
  # and the next flip updated only one of them; those are collapsed to one. And
  # a pairing the loaner import dropped kept its rows, which nothing updates any
  # more; those are removed.
  #
  # Runs per user rather than per row: `hidden` is a property of a whole
  # (model, wanted) group -- exactly one visible -- and repairing rows one at a
  # time in arbitrary order would hide all of them or leave several visible
  # depending on the order they arrived in.
  #
  # A task rather than a data migration, for the reason `BackfillHardpointBuilds`
  # records: `bin/deploy-release` runs `data:migrate` inside the Kamal pre-deploy
  # hook, and this walks every loaner in the database.
  #
  # Re-runnable, and no `dry_run` attribute -- one defaulting to true makes a
  # console run roll back silently while still reporting "succeeded".
  #
  # Nothing locks a parent against a concurrent save. `create_loaner` runs
  # inside the parent's own transaction, so a flip landing mid-batch can leave
  # one loaner holding the `wanted` read at the start of that user's rows --
  # the value it already holds today, corrected by the parent's next save or by
  # a re-run. Locking every parent would block real saves behind a batch job.
  class RepairLoanerFlagsTask < MaintenanceTasks::Task
    def collection
      User.where(id: Vehicle.where(loaner: true).select(:user_id))
    end

    def count
      collection.count
    end

    def process(user)
      loaners = Vehicle.where(loaner: true, user_id: user.id).includes(parent_vehicle: {model: :model_loaners}).to_a
      return if loaners.empty?

      loaners -= collapse_duplicates(loaners)
      loaners -= remove_unlisted(loaners)

      touched = realign_wanted(loaners) | revisit_hidden(loaners)

      touched.each { |loaner| schedule_fleet_update(loaner) }
    end

    # The row kept is the visible one where there is one, else the oldest -- the
    # same choice `Vehicle#create_loaner` makes. `destroy` rather than
    # `delete`, so the row's `fleet_vehicles` go with it.
    private def collapse_duplicates(loaners)
      loaners.select(&:vehicle_id).group_by { |loaner| [loaner.vehicle_id, loaner.model_id] }.flat_map do |_key, group|
        _kept, *duplicates = group.sort_by { |loaner| [loaner.hidden? ? 1 : 0, loaner.created_at] }
        duplicates.each(&:destroy)
      end
    end

    private def remove_unlisted(loaners)
      loaners.select do |loaner|
        parent = loaner.parent_vehicle
        next false if parent.nil?
        next false if parent.model.model_loaners.any? { |pairing| pairing.loaner_model_id == loaner.model_id }

        loaner.destroy
        true
      end
    end

    # A loaner without a parent is not this task's business: nothing says what
    # its `wanted` should be, and destroying it is a decision for whoever finds
    # out how it got orphaned.
    private def realign_wanted(loaners)
      loaners.select do |loaner|
        parent = loaner.parent_vehicle
        next false if parent.nil? || loaner.wanted == parent.wanted

        loaner.update_columns(wanted: parent.wanted, updated_at: Time.zone.now)
        true
      end
    end

    # One visible row per (model, wanted) group. The survivor is the one already
    # visible where there is one, so a repair does not move which loaner a user
    # sees when the group was correct apart from its neighbours.
    private def revisit_hidden(loaners)
      loaners.group_by { |loaner| [loaner.model_id, loaner.wanted] }.flat_map do |_group_key, group|
        visible = group.find { |loaner| !loaner.hidden? } || group.first

        group.select do |loaner|
          should_hide = !loaner.equal?(visible)
          next false if loaner.hidden? == should_hide

          loaner.update_columns(hidden: should_hide, updated_at: Time.zone.now)
          true
        end
      end
    end

    # `schedule_fleet_vehicle_update` is an `after_commit` that returns early for
    # a hidden vehicle, and `update_columns` skips callbacks anyway. Both are why
    # the fleet side is driven from here: a row we hide would otherwise keep the
    # `FleetVehicle` this task exists to remove.
    private def schedule_fleet_update(loaner)
      Updater::FleetVehicleUpdateJob.perform_async(loaner.id)
    end
  end
end
