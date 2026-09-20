# frozen_string_literal: true

module Loaders
  class UexComponentPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexComponentPricesImport.create(admin_user_id:)

      import.start!

      result = ::Uex::ComponentPriceSyncer.new.run

      # Three kinds of miss, and one of them is not work. A UEX item no component
      # is named by is mostly personal gear this catalogue does not carry; a name
      # several components answer to is a `MAPPINGS` entry somebody has to write,
      # and a mapping pointing at a component that is gone is one somebody has to
      # repoint. The report is actionable on the latter two.
      actionable = result.ambiguous.present? || result.stale_mappings.present?

      AdminReport.deliver(
        task_type: "uex_component_prices_import",
        title: actionable ? "UEX Component Sync — Items We Cannot Place" : "UEX Component Price Sync Results",
        body: ::Uex::ComponentPriceSyncer.github_issue_body(result),
        actionable:,
        record: import,
        report_key: "uex_component_prices"
      )

      import.update!(
        output: {
          created: result.created,
          updated: result.updated,
          removed: result.removed,
          skipped_removals: result.skipped_removals,
          unknown: result.unknown.map { |row| row["item_name"] },
          ambiguous: result.ambiguous.map { |row, sc_keys| "#{row["item_name"]} -> #{sc_keys.join(", ")}" },
          stale_mappings: result.stale_mappings.map { |row, sc_key| "#{row["item_name"]} -> #{sc_key}" }
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
