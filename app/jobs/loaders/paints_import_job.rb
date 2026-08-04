# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::PaintsImport.create(admin_user_id:)

      import.start!

      results = ::PaintsImporter.new.run

      if results[:new_with_error][:count].positive? || results[:model_not_found][:count].positive?
        GithubIssueCreator.new(
          task_type: "paints_import",
          title: "Paints Import Results",
          body: ::PaintsImporter.github_issue_body(results)
        ).run
      end

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
