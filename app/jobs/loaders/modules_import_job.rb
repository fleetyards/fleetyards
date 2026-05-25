# frozen_string_literal: true

module Loaders
  class ModulesImportJob < ::Loaders::BaseJob
    def perform
      import = Imports::ModulesImport.create

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
