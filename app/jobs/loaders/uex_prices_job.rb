# frozen_string_literal: true

module Loaders
  class UexPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexPricesImport.create(admin_user_id:)

      import.start!

      result = ::Uex::PriceSyncer.new.run

      if result.unmatched.present?
        GithubIssueCreator.new(
          task_type: "uex_prices_import",
          title: "UEX Price Sync — Unmatched Vehicles",
          body: ::Uex::PriceSyncer.github_issue_body(result)
        ).run
      end

      import.update!(
        output: {
          created: result.created,
          updated: result.updated,
          removed: result.removed,
          skipped_removals: result.skipped_removals,
          unmatched: result.unmatched.map { |vehicle| vehicle["slug"] }
        }
      )
      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
