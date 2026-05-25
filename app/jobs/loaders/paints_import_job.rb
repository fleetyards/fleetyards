# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform
      import = Imports::PaintsImport.create

      import.start!

      results = ::PaintsImporter.new.run

      GithubIssueCreator.new(
        task_type: "paints_import",
        title: "Paints Import Results",
        body: ::PaintsImporter.github_issue_body(results)
      ).run

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
