# frozen_string_literal: true

module Maintenance
  class ModulesImportTask < MaintenanceTasks::Task
    no_collection

    def process
      results = ::ModulesImporter.new.run

      GithubIssueCreator.new(
        task_type: "modules_import",
        title: "Modules Import Results",
        body: ::ModulesImporter.github_issue_body(results)
      ).run
    end
  end
end
