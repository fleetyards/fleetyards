# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil, model_id = nil)
      model = Model.find(model_id) if model_id.present?

      import = Imports::PaintsImport.create(admin_user_id:, input: model.present? ? {model_id: model.id} : nil)

      import.start!

      results = ::PaintsImporter.new(model:).run

      AdminReport.deliver(
        task_type: "paints_import",
        title: model.present? ? "Paints Import Results for #{model.name}" : "Paints Import Results",
        body: ::PaintsImporter.github_issue_body(results),
        actionable: ::PaintsImporter.actionable?(results),
        # A targeted run reports on a single model, so it needs its own dedupe
        # key -- otherwise its small body becomes "last seen" for the full run.
        report_key: model.present? ? "paints_import_#{model.id}" : nil,
        record: import
      )

      import.finish!
    rescue => e
      # The model lookup happens before the import exists -- a model deleted
      # between enqueue and run leaves nothing to mark as failed.
      import&.fail!
      import&.update!(info: e.message)

      raise e
    end
  end
end
