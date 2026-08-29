# frozen_string_literal: true

module Versions
  # Puts one field of one record back to the value a version recorded before it.
  #
  # One field rather than the whole version, because a version written by a
  # loader usually carries a dozen fields an admin has no quarrel with -- the
  # matrix moving `mass` and `cargo` together, when only `mass` was wrong.
  class FieldReverter
    Result = Struct.new(:record, :field, :from, :to) do
      def missing? = record.blank?

      def success? = record.present? && record.errors.empty?
    end

    def initialize(version, field, author_id: nil)
      @version = version
      @field = field.to_s
      @author_id = author_id
    end

    def run
      return Result.new(nil, @field) if record.blank?

      return failure(:unknown_field) unless reversible?

      before, after = @version.changeset.fetch(@field)
      before = cast(before)

      return failure(:already_reverted) if record.public_send(@field) == before

      write(before)

      Result.new(record, @field, cast(after), before)
    end

    # Only a field the version actually recorded a change for, and only one the
    # record still has -- a changeset survives a migration that drops its column.
    #
    # Only an update, too. Six of the ten catalogues track creates as well, and a
    # create's changeset reads as "every column, from nothing" -- reverting one
    # is not undoing a change, it is blanking a column that never had a previous
    # value.
    private def reversible?
      @version.event == "update" &&
        @version.changeset.key?(@field) &&
        record.class.column_names.include?(@field)
    end

    # A changeset is JSON, so a decimal comes back as a string and would never
    # equal the column it is being compared against.
    private def cast(value)
      record.class.type_for_attribute(@field).cast(value)
    end

    private def record
      return @record if defined?(@record)

      @record = @version.item
    end

    # An admin correction to a Model has to reach the build as well as the row,
    # which is what `update_with_facts` is for. Nothing else in this list keeps
    # its facts anywhere but its own columns.
    private def write(value)
      attributes = {@field => value}.merge(meta)

      return record.update_with_facts(attributes) if record.respond_to?(:update_with_facts)

      record.update(attributes)
    end

    # Four of the ten declare paper_trail meta, so the version this revert writes
    # says who did it and why. The other six have nowhere to put that.
    private def meta
      return {} unless record.respond_to?(:update_reason=)

      {
        author_id: @author_id,
        update_reason: :custom,
        update_reason_description: "Reverted #{@field}"
      }
    end

    private def failure(code)
      # On `:base` rather than the field: `full_message` prefixes a humanised
      # attribute name, and "field" is not one this record has.
      record.errors.add(:base, code, message: I18n.t(:"validation_error.version.#{code}"))

      Result.new(record, @field)
    end
  end
end
