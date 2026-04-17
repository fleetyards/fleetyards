# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform
      results = ::PaintsImporter.new.run

      GithubIssueCreator.new(
        task_type: "paints_import",
        title: "Paints Import Results",
        body: ::PaintsImporter.github_issue_body(results)
      ).run
    end
  end
end
