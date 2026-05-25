# frozen_string_literal: true

module Loaders
  class ModulesImportJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::ModulesImport.create(admin_user_id:)

      import.start!

      results = ::ModulesImporter.new.run

      GithubIssueCreator.new(
        task_type: "modules_import",
        title: "Modules Import Results",
        body: ::ModulesImporter.github_issue_body(results)
      ).run

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
