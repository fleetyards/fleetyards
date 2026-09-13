# frozen_string_literal: true

module Inventories
  # Telling the operators there is something to look at.
  #
  # One row for the whole queue rather than one per report, keyed on the queue
  # itself. `Oauth::Application#report_for_review` already establishes the shape
  # and the reason: anyone can sign up, so a per-record notification turns a
  # spree into an inbox nobody reads -- and a per-sender cap cannot prevent that
  # either, because the senders are the thing being created.
  class TransferReportQueue
    DEDUPE_KEY = "inventory_transfer_reports"

    def self.announce
      waiting = ::InventoryTransferReport.open_queue.count
      latest = ::InventoryTransferReport.open_queue.first

      ::AdminNotification.notify!(
        type: :inventory_transfer_reports,
        title: "#{waiting} transfer #{"report".pluralize(waiting)} awaiting review",
        body: latest && "Most recent: #{latest.reason} reported by #{latest.reporter&.username || "a deleted account"}",
        severity: :warning,
        link: "/inventory-transfer-reports",
        record: latest,
        dedupe_key: DEDUPE_KEY
      )
    end
  end
end
