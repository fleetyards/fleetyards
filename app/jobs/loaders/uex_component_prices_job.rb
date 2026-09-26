# frozen_string_literal: true

module Loaders
  class UexComponentPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexComponentPricesImport.create(admin_user_id:)

      import.start!

      result = ::Uex::ComponentPriceSyncer.new.run

      # Four kinds of miss, and one of them is not work: a priced item outside
      # every section a ship carries from is a pair of trousers, not a gap. The
      # other three all want a person -- an unplaceable ship part may be a
      # rename that has silently taken its prices with it, an ambiguous name
      # wants a `MAPPINGS` entry, and a stale mapping wants repointing.
      actionable = result.unknown.present? || result.ambiguous.present? || result.stale_mappings.present?

      AdminReport.deliver(
        task_type: "uex_component_prices_import",
        title: actionable ? "UEX Component Sync — Items We Cannot Place" : "UEX Component Price Sync Results",
        body: ::Uex::ComponentPriceSyncer.github_issue_body(result),
        notification_body: ::Uex::ComponentPriceSyncer.notification_body(result),
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
          # Not in the issue body, which is deduped on a digest and would open a
          # fresh issue every time UEX listed another jacket. Counted here, where
          # nothing dedupes, so a sudden jump is still visible.
          unknown_other: result.unknown_other.size,
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
