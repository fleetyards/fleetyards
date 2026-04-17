# frozen_string_literal: true

module Loaders
  class ModulesImportJob < ::Loaders::BaseJob
    def perform
      results = ::ModulesImporter.new.run

      GithubIssueCreator.new(
        task_type: "modules_import",
        title: "Modules Import Results",
        body: ::ModulesImporter.github_issue_body(results)
      ).run
    end
  end
end
