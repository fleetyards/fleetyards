# frozen_string_literal: true

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::PaintsImport.create(admin_user_id:)

      import.start!

      # Serialize per task so a clean run's resolve can't close an issue a concurrent
      # problematic run just opened. Both recompute their results while holding the lock.
      ApplicationRecord.with_advisory_lock("loaders:paints_import") do
        results = ::PaintsImporter.new.run

        creator = GithubIssueCreator.new(
          task_type: "paints_import",
          title: "Paints Import Results",
          body: ::PaintsImporter.github_issue_body(results)
        )

        if results[:new_with_error][:count].positive? || results[:model_not_found][:count].positive?
          creator.run
        else
          creator.resolve
        end
      end

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
