# frozen_string_literal: true

module Maintenance
  # Drops the versions paper_trail filed for a `touch`.
  #
  # Rails' `touch` does no dirty-tracking, so `Events::Update#record_object_changes?`
  # returns false for one and the row is written with no `object_changes` at all.
  # There is nothing in it to show and nothing to put back -- the admin history
  # rendered each as a heading with an empty body.
  #
  # `Fleet` and the six models beside it now name their events without `:touch`,
  # so no more are written. This clears the 572,773 already on disk: 572,735 on
  # `Fleet`, whose seven `touch: true` children filed one per write, and 38 on
  # `FleetInventory`. Both had roughly a thousand of these per real edit.
  #
  # A maintenance task rather than a data migration: it destroys rows and cannot
  # be undone, and `data:migrate` runs unattended on every deploy. Here it is run
  # deliberately, once per environment, with `dry_run` first.
  #
  # It clears nine rows in ten, so follow it with `VACUUM ANALYZE versions` for
  # the planner's sake rather than waiting for autovacuum. That marks the space
  # reusable without returning it to the disk; only `VACUUM FULL` does that, and
  # it holds an exclusive lock for the rewrite.
  class DropChangelessVersionsTask < MaintenanceTasks::Task
    no_collection

    # Small enough that a cancelled run leaves a short statement behind, large
    # enough that the whole set is a few hundred of them.
    BATCH_SIZE = 5_000

    # Left on by default so an accidental run reports instead of destroying.
    attribute :dry_run, :boolean, default: true

    # `old_object_changes` is the pre-json column, empty on every row in this
    # database. A row that did carry one would be real history that predates the
    # migration, so the guard keeps it out of scope rather than trusting that.
    #
    # `create` and `destroy` are excluded for the same reason: paper_trail always
    # records a changeset for them, so one arriving here without would be a row
    # this task does not understand.
    def self.changeless
      PaperTrail::Version.where(event: "update", object_changes: nil, old_object_changes: nil)
    end

    def process
      dry_run ? report_plan : apply
    end

    private def apply
      before = self.class.changeless.count
      deleted = 0

      self.class.changeless.in_batches(of: BATCH_SIZE) { |batch| deleted += batch.delete_all }

      log "deleted #{deleted} of #{before} changeless versions"
      log "versions left: #{PaperTrail::Version.count}"
    end

    private def report_plan
      scope = self.class.changeless

      scope.group(:item_type).count.sort.each do |item_type, count|
        log "#{item_type}: #{count} changeless of #{PaperTrail::Version.where(item_type:).count}"
      end

      log "changeless versions: #{scope.count} of #{PaperTrail::Version.count}"
      log "dry run -- nothing was deleted"
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
