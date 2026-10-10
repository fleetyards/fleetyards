# frozen_string_literal: true

module Maintenance
  # Until April 2026 the hangar sync called `to_json` before writing `input` and
  # `output`, which are jsonb, so every older sync stores a JSON string instead
  # of the object it describes and `Imports::HangarSync#result_details` raises on
  # it. Legacy hangar imports were written the same way, so every import type is
  # covered. Only strings holding a JSON object or array are unwrapped: some
  # legacy imports hold the string "null", and a malformed one would fail the
  # whole batch.
  #
  # A task rather than a data migration: it rewrites ~125k rows and ~550 MB of
  # jsonb, which would hold up the Kamal pre-deploy hook for minutes. Re-runnable:
  # an unwrapped row is no longer in the collection.
  class UnwrapDoubleEncodedImportsTask < MaintenanceTasks::Task
    COLUMNS = %w[input output].freeze
    BATCH_SIZE = 500

    def self.wrapped(column)
      "jsonb_typeof(#{column}) = 'string' AND " \
        "((#{column} #>> '{}') IS JSON OBJECT OR (#{column} #>> '{}') IS JSON ARRAY)"
    end

    def collection
      Import.where(COLUMNS.map { |column| "(#{self.class.wrapped(column)})" }.join(" OR "))
        .in_batches(of: BATCH_SIZE)
    end

    def process(batch)
      batch.update_all(
        COLUMNS.map { |column|
          "#{column} = CASE WHEN #{self.class.wrapped(column)} THEN (#{column} #>> '{}')::jsonb ELSE #{column} END"
        }.join(", ")
      )
    end
  end
end
