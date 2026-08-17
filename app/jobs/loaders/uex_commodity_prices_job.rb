# frozen_string_literal: true

module Loaders
  class UexCommodityPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexCommodityPricesImport.create(admin_user_id:)

      import.start!

      # Prices join on uex_id, so anything the last game-file import added has to
      # be mapped before the snapshot runs or its prices are dropped as unknown.
      mapping = ::Uex::CommodityMapper.new.run
      result = ::Uex::CommodityPriceSyncer.new.run

      unmapped = mapping.unmapped.present?
      unknown = result.unknown.present?

      AdminReport.deliver(
        task_type: "uex_commodity_prices_import",
        title: unmapped ? "UEX Commodity Sync — Unmapped Commodities" : "UEX Commodity Mapping Results",
        body: ::Uex::CommodityMapper.github_issue_body(mapping),
        actionable: unmapped,
        record: import
      )

      AdminReport.deliver(
        task_type: "uex_commodity_prices_import",
        title: unknown ? "UEX Commodity Sync — Priced Commodities We Do Not Carry" : "UEX Commodity Price Sync Results",
        body: ::Uex::CommodityPriceSyncer.github_issue_body(result),
        actionable: unknown,
        record: import
      )

      import.update!(
        output: {
          mapped: mapping.mapped,
          remapped: mapping.updated,
          unmapped: mapping.unmapped.map(&:sc_key),
          created: result.created,
          updated: result.updated,
          removed: result.removed,
          skipped_removals: result.skipped_removals,
          unknown: result.unknown.map { |row| row["commodity_name"] }
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
