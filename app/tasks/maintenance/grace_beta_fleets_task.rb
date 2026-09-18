# frozen_string_literal: true

module Maintenance
  # Opens a dated grace subscription for every fleet that has been reaching a
  # premium capability behind a Flipper actor gate.
  #
  # The beta fleets tested unfinished work, and the fair thing is not a
  # permanent free ride -- it is knowing in advance. The announcement names the
  # date; this keeps them running past it while they decide.
  #
  # A maintenance task rather than a data migration for two reasons: it reads
  # Flipper, which a schema migration has no business doing, and it wants to be
  # runnable again after the numbers have been looked at. `data:migrate` runs
  # unattended on every deploy, which is the opposite of what this needs.
  #
  # `ended_at` is set on the way in rather than left open, so the window closes
  # by itself under the live read in FleetSubscription -- no second task, and
  # nothing to remember three months from now. A grace row has no contribution
  # behind it, so the reconciler leaves it alone.
  class GraceBetaFleetsTask < MaintenanceTasks::Task
    no_collection

    # Left on by default so an accidental run reports instead of granting.
    attribute :dry_run, :boolean, default: true

    # Three months from the run. A permanent comp is the option to avoid: the
    # fleets that tested hardest are the ones most likely to subscribe, and
    # comping them forever removes exactly that group.
    attribute :months, :integer, default: 3

    # Named in the note so a row found later says what granted it. The
    # announcement is the answer to "why does this fleet have this".
    attribute :note, :string, default: "Beta grace window — premium transition announcement"

    def process
      readiness = ::Subscriptions::Readiness.call

      report(readiness)

      return if halted?(readiness)

      dry_run ? report_plan(readiness) : grant(readiness)
    end

    private def report(readiness)
      log "fleets behind an actor gate: #{readiness[:gated_fleet_ids].size}"
      log "of those, already subscribed: #{readiness[:subscribed_fleet_ids].size}"
      log "of those, would be cut off:   #{readiness[:unready_fleet_ids].size}"
    end

    # A flag switched on for everybody has no actor list to read and every
    # fleet is reaching it, so the figures above describe the wrong population.
    # Granting against them would open a subscription for a handful of fleets
    # and quietly miss the rest, which is worse than doing nothing.
    private def halted?(readiness)
      return false if readiness[:globally_on].empty?

      log "STOP: #{readiness[:globally_on].join(", ")} on for everybody, so the gate list is not the population"
      log "Switch them back to actor gates, or grace by hand, before running this."
      true
    end

    private def report_plan(readiness)
      log "dry run — nothing written. #{readiness[:unready_fleet_ids].size} would be graced until #{ends_on}."

      Fleet.where(id: readiness[:unready_fleet_ids]).order(:name).limit(50).pluck(:name).each { |name| log "  #{name}" }
    end

    private def grant(readiness)
      fleet_ids = readiness[:unready_fleet_ids]

      fleet_ids.each do |fleet_id|
        FleetSubscription.create!(
          fleet_id:,
          granted_via: "manual",
          started_at: Date.current,
          ended_at: ends_on,
          note:
        )
      end

      log "granted #{fleet_ids.size} fleets a subscription until #{ends_on}"
    end

    private def ends_on
      @ends_on ||= Date.current + months.months
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
