# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    # What the pledge store step writes that paper_trail does not watch, because
    # a sale would flip it on dozens of ships at once. The first sighting of an
    # upgrade only ever arrives with `ccu_on_sale`, so `ccu_target_seen_at` is
    # not named as well.
    STORE_COLUMNS = %w[on_sale ccu_on_sale rsi_pledge_slug rsi_pledge_value rsi_ctm_url].freeze

    # `follow_ups` are loader keys started once the matrix is in: loaners,
    # modules, paints and prices all match against the ships this run may add.
    # Outside the run's own rescue, which can fail an import only while it is
    # still running.
    def perform(admin_user_id = nil, follow_ups = [])
      load_matrix(admin_user_id)

      start_follow_ups(admin_user_id, follow_ups)
    end

    private def load_matrix(admin_user_id)
      import = Imports::ModelsImport.create(admin_user_id:)

      import.start!

      started_at = Time.current
      store_values_before = store_values

      ::Rsi::ModelsLoader.new.all

      AdminReport.deliver(
        task_type: "ship_matrix_import",
        title: "Ship Matrix Import Results",
        body: results_body(started_at, store_values_before),
        # A run that changes nothing is the normal case for a matrix that moves
        # a few times a month, so it never opens an issue. A run that breaks
        # raises, and the import's own notification carries that.
        actionable: false,
        link: "/models",
        record: import
      )

      ::Models::UnplacedFoci.report(record: import)

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end

    # Each on its own: one that cannot be queued is reported and the rest still
    # start. Raising here would retry the job, and run the matrix again.
    private def start_follow_ups(admin_user_id, follow_ups)
      Array(follow_ups).each do |key|
        ::Imports::Loaders.new(key, admin_user_id:).enqueue
      rescue => e
        Appsignal.report_error(e)
        Rails.logger.error("[#{self.class.name}] could not start #{key}: #{e.message}")
      end
    end

    # `Rsi::ModelsLoader` returns nothing countable, so the run is measured on
    # either side of it. Both sides of the change are named, because a matrix
    # that moves a few times a month makes "1 model updated" a question rather
    # than a report.
    private def results_body(started_at, store_values_before)
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
        store_fields = changed_store_fields(store_values_before)

        lines += ["", "### Updated", "", *updated.map { |model| updated_line(model, changed_fields[model.id], store_fields[model.id]) }]
      end

      lines.join("\n")
    end

    private def updated_line(model, fields, store_fields)
      adopted, matrix_only = split_fields(Array(fields))

      notes = []
      notes << "matrix only: #{matrix_only.join(", ")}" if matrix_only.any?
      notes << "store: #{store_fields.join(", ")}" if store_fields.present?

      return "- **#{model.name}**" if adopted.empty? && notes.empty?
      return "- **#{model.name}**: #{notes.join("; ")}" if adopted.empty?
      return "- **#{model.name}**: #{adopted.join(", ")}" if notes.empty?

      "- **#{model.name}**: #{adopted.join(", ")} (#{notes.join("; ")})"
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

    # paper_trail does not watch `last_updated_at` and the store image, which move
    # on nearly every matrix change and carry no value of their own, nor
    # `STORE_COLUMNS`, which are compared across the run instead. A run that
    # touched only `last_updated_at` or the image is named without fields.
    private def changed_fields_by_model(started_at)
      PaperTrail::Version
        .where(item_type: "Model", created_at: started_at..)
        .group_by(&:item_id)
        .transform_values { |versions| versions.flat_map { |version| version.changeset.keys }.uniq.sort }
    end

    private def store_values
      Model.pluck(:id, *STORE_COLUMNS).to_h { |id, *values| [id, values] }
    end

    private def changed_store_fields(values_before)
      store_values.to_h { |id, values|
        before = values_before.fetch(id, values)

        [id, STORE_COLUMNS.zip(before, values).filter_map { |column, old, new| column if old != new }.sort]
      }
    end
  end
end
