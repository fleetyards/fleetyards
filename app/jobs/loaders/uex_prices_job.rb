# frozen_string_literal: true

module Loaders
  class UexPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexPricesImport.create(admin_user_id:)

      import.start!

      result = ::Uex::PriceSyncer.new.run

      unmatched = result.unmatched.present?

      AdminReport.deliver(
        task_type: "uex_prices_import",
        title: unmatched ? "UEX Price Sync — Unmatched Vehicles" : "UEX Price Sync Results",
        body: ::Uex::PriceSyncer.github_issue_body(result),
        actionable: unmatched,
        record: import
      )

      import.update!(
        output: {
          created: result.created,
          updated: result.updated,
          removed: result.removed,
          skipped_removals: result.skipped_removals,
          repriced: result.repriced,
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
