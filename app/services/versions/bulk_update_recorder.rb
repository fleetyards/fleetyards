# frozen_string_literal: true

module Versions
  # Files paper_trail versions for rows that a single `update_all` changed.
  #
  # That statement is what skips the callbacks paper_trail hangs off, so the
  # versions have to be written next to it rather than by it. Reaching for
  # paper_trail's own update event rather than assembling the rows here is what
  # keeps them indistinguishable from the versions a normal save files: enums
  # land as their names, timestamps and decimals in the shapes the json columns
  # already hold everywhere else.
  #
  # The records have to arrive carrying the new values in memory and still
  # holding the old ones in the database -- assigned, not saved. That is what
  # makes `object` the state *before* the change: the event reads each attribute
  # from the database, and dirty tracking keeps the pre-change value there.
  # `paper_trail.update_columns` looks like the shortcut for this and is not; it
  # clears dirty state first, so its `object` describes the row afterwards.
  class BulkUpdateRecorder
    def self.record(records, column_values, reason: nil)
      new(records, column_values, reason:).record
    end

    def initialize(records, column_values, reason: nil)
      @records = records
      @column_values = column_values
      @reason = reason
    end

    def record
      return if @records.blank? || !recording?

      rows = @records.filter_map { |record| version_row(record) }

      return if rows.empty?

      PaperTrail::Version.insert_all(rows)
    end

    private def recording?
      PaperTrail.enabled? && PaperTrail.request.enabled? &&
        @records.map(&:class).uniq.all? { |klass| PaperTrail.request.enabled_for_model?(klass) }
    end

    # `Events::Update` is paper_trail's internal API, which is the trade for
    # getting its serialization for free. The arguments: no after-callback (so
    # the pre-change values are read from the database), not a touch, and no
    # forced changeset -- dirty tracking already has the right one.
    private def version_row(record)
      record.assign_attributes(@column_values)

      return unless changed_beyond_timestamps?(record)

      data = ::PaperTrail::Events::Update.new(record, false, false, nil).data

      {
        item_type: record.class.name,
        item_id: record.id,
        event: data[:event],
        whodunnit: data[:whodunnit],
        object: data[:object],
        object_changes: data[:object_changes],
        # What wrote the version, so a reader can tell one row of a group apart
        # from a change somebody made to that row alone.
        reason: @reason,
        # Matched to the row's own `updated_at`, the way paper_trail lines a
        # version up with the save that produced it.
        created_at: record.updated_at
      }
    end

    # A change that moved nothing but `updated_at` is the changeless version
    # `Maintenance::DropChangelessVersionsTask` exists to clear out again, so it
    # is not written in the first place. Re-submitting a position's current name
    # is the ordinary way to arrive here.
    private def changed_beyond_timestamps?(record)
      timestamps = record.send(:timestamp_attributes_for_update_in_model).map(&:to_s)

      (record.changed - timestamps).any?
    end
  end
end
