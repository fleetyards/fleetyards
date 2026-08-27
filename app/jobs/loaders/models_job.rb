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
    # either side of it. New models are named because that is the part of the
    # report worth reading; an update is a field nobody can name from here.
    private def results_body(started_at)
      added = Model.where(created_at: started_at..).order(:name)
      updated = Model.where(updated_at: started_at..).where(created_at: ...started_at).count

      lines = [
        "## Ship Matrix Import",
        "",
        "- **Models added**: #{added.count}",
        "- **Models updated**: #{updated}",
        "- **Models in total**: #{Model.count}"
      ]

      return lines.join("\n") if added.empty?

      (lines + ["", "### Added", "", *added.map { |model| "- **#{model.name}**" }]).join("\n")
    end
  end
end
