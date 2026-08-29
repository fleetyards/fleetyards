# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::ModelsImport.create(admin_user_id:)

      import.start!

      started_at = Time.current

      ::Rsi::ModelsLoader.new.all

      AdminReport.deliver(
        task_type: "ship_matrix_import",
        title: "Ship Matrix Import Results",
        body: results_body(started_at),
        # A run that changes nothing is the normal case for a matrix that moves
        # a few times a month, so it never opens an issue. A run that breaks
        # raises, and the import's own notification carries that.
        actionable: false,
        link: "/models",
        record: import
      )

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end

    # `Rsi::ModelsLoader` returns nothing countable, so the run is measured on
    # either side of it. Both sides of the change are named, because a matrix
    # that moves a few times a month makes "1 model updated" a question rather
    # than a report.
    private def results_body(started_at)
      added = Model.where(created_at: started_at..).order(:name)
      updated = Model.where(updated_at: started_at..).where(created_at: ...started_at).order(:name)

      lines = [
        "## Ship Matrix Import",
        "",
        "- **Models added**: #{added.count}",
        "- **Models updated**: #{updated.count}",
        "- **Models in total**: #{Model.count}"
      ]

      lines += ["", "### Added", "", *added.map { |model| "- **#{model.name}**" }] if added.any?

      if updated.any?
        changed_fields = changed_fields_by_model(started_at)

        lines += ["", "### Updated", "", *updated.map { |model| updated_line(model, changed_fields[model.id]) }]
      end

      lines.join("\n")
    end

    private def updated_line(model, fields)
      return "- **#{model.name}**" if fields.blank?

      adopted, matrix_only = split_fields(fields)

      return "- **#{model.name}**: matrix only: #{matrix_only.join(", ")}" if adopted.empty?

      line = "- **#{model.name}**: #{adopted.join(", ")}"

      return line if matrix_only.empty?

      "#{line} (matrix only: #{matrix_only.join(", ")})"
    end

    # A shadow that moved with its live column is one change, named once. A
    # shadow that moved alone is the matrix offering a value the loader's guards
    # refused -- named under the live column it was offered for, because that is
    # the value an admin would go looking at.
    private def split_fields(fields)
      shadow, adopted = fields.partition { |field| field.start_with?("rsi_") }

      matrix_only = shadow.filter_map { |field|
        offered_for = field.delete_prefix("rsi_")

        next if adopted.include?(offered_for)

        Model.column_names.include?(offered_for) ? offered_for : field
      }

      [adopted, matrix_only.uniq.sort]
    end

    # paper_trail watches every column this loader writes except `last_updated_at`
    # and the store image, which move on nearly every matrix change and carry no
    # value of their own. A run that touched only those is named without fields.
    private def changed_fields_by_model(started_at)
      PaperTrail::Version
        .where(item_type: "Model", created_at: started_at..)
        .group_by(&:item_id)
        .transform_values { |versions| versions.flat_map { |version| version.changeset.keys }.uniq.sort }
    end
  end
end
