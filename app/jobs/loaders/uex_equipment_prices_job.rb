# frozen_string_literal: true

module Loaders
  class UexEquipmentPricesJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::UexEquipmentPricesImport.create(admin_user_id:)

      import.start!

      result = ::Uex::EquipmentPriceSyncer.new.run

      # A priced item outside every gear section is a ship part or a sandwich,
      # not a gap, so it is counted and left alone.
      actionable = result.unknown.present? || result.ambiguous.present? || result.stale_mappings.present?

      AdminReport.deliver(
        task_type: "uex_equipment_prices_import",
        title: actionable ? "UEX Equipment Sync — Items We Cannot Place" : "UEX Equipment Price Sync Results",
        body: ::Uex::EquipmentPriceSyncer.github_issue_body(result),
        notification_body: ::Uex::EquipmentPriceSyncer.notification_body(result),
        actionable:,
        record: import,
        report_key: "uex_equipment_prices"
      )

      import.update!(
        output: {
          created: result.created,
          updated: result.updated,
          removed: result.removed,
          skipped_removals: result.skipped_removals,
          unknown: result.unknown.map { |row| row["item_name"] },
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
