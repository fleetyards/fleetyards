# frozen_string_literal: true

module Uex
  class CommodityPriceSyncer
    include Uex::PriceSnapshot

    ITEM_TYPE = "Commodity"
    TERMINAL_TYPE = "commodity"

    Result = Struct.new(:created, :updated, :removed, :skipped_removals, :unknown, :terminals) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} " \
          "skipped_removals=#{skipped_removals} unknown=#{unknown.size} terminals=(#{terminals})"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      terminal_sync = Uex::TerminalSyncer.new(client: @client).run
      terminals = terminal_sync.terminals
      prices = require_rows(:commodity_prices, @client.commodity_prices)

      # The mapper has already resolved names to ids, so the price feed needs no
      # matching of its own -- a commodity we never mapped simply has no entry.
      commodities = Commodity.where.not(uex_id: nil).select(:id, :uex_id).index_by(&:uex_id)
      unknown = {}

      desired = collect(prices, commodities:, terminals:, unknown:)
      counts = persist_prices(desired, live: terminal_sync.live_ids)

      record_price_history

      Result.new(
        created: counts.created,
        updated: counts.updated,
        removed: counts.removed,
        skipped_removals: counts.skipped_removals,
        unknown: unknown.values,
        terminals: terminal_sync
      )
    end

    private def collect(rows, commodities:, terminals:, unknown:)
      rows.each_with_object({}) do |row, result|
        terminal = terminals[row["id_terminal"]]
        next if terminal.blank?

        commodity_id = Uex::CommodityMatcher::DUPLICATES.fetch(row["id_commodity"], row["id_commodity"])
        commodity = commodities[commodity_id]

        if commodity.blank?
          unknown[row["id_commodity"]] ||= row
          next
        end

        updated_at = row["date_modified"].to_i.positive? ? Time.zone.at(row["date_modified"].to_i) : nil

        # UEX writes prices from the player's side: what they pay is price_buy,
        # what they receive is price_sell. Ours is shop-perspective, the way
        # ItemPrice is read everywhere else, so the two swap over. The stock
        # follows the price: scu_buy is what the player can buy, scu_sell_stock
        # what the terminal will take.
        add(result, row["price_buy"], commodity:, terminal:, price_type: "sell", scu: row["scu_buy"], updated_at:)
        add(result, row["price_sell"], commodity:, terminal:, price_type: "buy", scu: row["scu_sell_stock"], updated_at:)
      end
    end

    private def add(result, value, commodity:, terminal:, price_type:, scu:, updated_at:)
      price = value.to_d
      return if price <= 0

      attributes = {
        item_type: ITEM_TYPE,
        item_id: commodity.id,
        price_type:,
        location: terminal.name,
        time_range: nil,
        terminal_id: terminal.id,
        location_url: terminal.contact_url,
        price:,
        scu: scu.to_i.positive? ? scu.to_i : nil,
        source_updated_at: updated_at
      }

      key = price_key(attributes)
      existing = result[key]

      return result[key] = attributes if existing.blank?

      # Only a UEX duplicate and the id it duplicates share a key, and which of
      # the pair to keep depends on the direction: of two prices for cargo a
      # shop sells the player wants the cheaper, of two it buys the better paid.
      better = (price_type == "sell") ? price < existing[:price] : price > existing[:price]

      result[key] = attributes if better
    end

    # Deliberately free of the sync counts: GithubIssueCreator dedupes on a
    # digest of the body, and prices move every day, so anything volatile in
    # here would open a fresh issue on every run.
    def self.github_issue_body(result)
      lines = ["## Priced UEX Commodities We Do Not Carry (#{result.unknown.size})", ""]
      lines << "UEX prices these at a commodity terminal but they resolve to no `Commodity`,"
      lines << "so the prices are dropped. Either the game files do not declare them,"
      lines << "`Uex::CommodityMatcher::MAPPINGS` is missing an entry, or UEX lists the"
      lines << "good twice and `Uex::CommodityMatcher::DUPLICATES` is missing one."
      lines << ""

      result.unknown.each do |row|
        lines << "- **#{row["commodity_name"]}** — UEX id `#{row["id_commodity"]}`"
      end

      lines.join("\n")
    end

    def self.notification_body(result)
      terminals = result.terminals
      lines = ["## Synced", ""]
      lines << "- **Terminals**: #{terminals.created} created, #{terminals.updated} updated, #{terminals.retired} retired"
      lines.concat(PriceSnapshot.notification_lines(result))
      lines << ""
      lines << (result.unknown.any? ? github_issue_body(result) : "Every priced UEX commodity resolved to one we carry.")
      lines.join("\n")
    end
  end
end
