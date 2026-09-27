# frozen_string_literal: true

module Loaders
  class UexTradeRoutesJob < ::Loaders::BaseJob
    # Hourly, so a clean run only logs. A notification per run would bury the
    # daily reports; only commodities that could not be fetched are worth one.
    def perform
      terminals = ::Uex::TerminalSyncer.new.run
      result = ::Uex::TradeRouteSyncer.new.run

      Rails.logger.info("[#{self.class.name}] terminals=(#{terminals}) #{result}")

      return if result.failed.empty?

      AdminReport.deliver(
        task_type: "uex_trade_routes_sync",
        title: "UEX Trade Route Sync — Commodities Not Fetched",
        body: self.class.failure_body(result),
        actionable: true,
        github_issue: false
      )
    end

    # The failed commodities only, so a failure that repeats every hour keeps
    # updating one unread notification instead of adding a row per run.
    def self.failure_body(result)
      lines = ["## Commodities Not Fetched (#{result.failed.size})", ""]
      lines << "UEX answered these route requests with an error. Their previous routes are kept"
      lines << "until a later run fetches them."
      lines << ""
      result.failed.sort_by(&:name).each { |commodity| lines << "- **#{commodity.name}** — UEX id `#{commodity.uex_id}`" }
      lines.join("\n")
    end
  end
end
