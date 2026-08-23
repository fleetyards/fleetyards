# frozen_string_literal: true

module Maintenance
  # Collapses the manufacturers the sc_data loader duplicated before it learned
  # to reuse a name it already has, and corrects the names the export mislabelled.
  #
  # A maintenance task rather than a data migration: it destroys rows and cannot
  # be undone, and `data:migrate` runs unattended on every deploy. Here it is run
  # deliberately, once per environment, with `dry_run` first.
  class DedupeManufacturersTask < MaintenanceTasks::Task
    no_collection

    # The rows the loader created under a name the export got wrong. Applied here
    # rather than by the loader, which deliberately never rewrites `name` because
    # a curated one beats the game's -- these are the exceptions to that, so they
    # are named explicitly rather than taken from the parsed data wholesale.
    CORRECTIONS = {
      "MXOX" => "maxOx",
      "PRAR" => "Preacher Armaments",
      "FSKI" => "Firestorm Kinetics"
    }.freeze

    # Placeholder records: copies of another manufacturer, logo included, that
    # nothing in the export references. Dropped only while nothing points at them.
    DROPPED_CODES = %w[TRAS GHEX].freeze

    # Left on by default so an accidental run reports instead of destroying.
    attribute :dry_run, :boolean, default: true

    def process
      dry_run ? report_plan : apply
    end

    private def apply
      result = deduplicator(logger: method(:log)).call

      log "renamed #{result.renamed.size}, dropped #{result.dropped.size}, " \
          "merged #{result.merged.size} slugs"
    end

    private def report_plan
      plan = deduplicator.plan

      plan[:log].each { |line| log line }

      log "manufacturers: #{plan[:before]} -> #{plan[:after]}"
      log "renamed #{plan[:renamed].size}, dropped #{plan[:dropped].size}, " \
          "merged #{plan[:merged].size} slugs"
      log "records left without a manufacturer: #{plan[:orphaned]}"
      log "dry run -- rolled back, no rows were changed"
    end

    private def deduplicator(logger: nil)
      ::Manufacturers::Deduplicator.new(
        corrections: CORRECTIONS,
        dropped_codes: DROPPED_CODES,
        logger:
      )
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
