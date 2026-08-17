# frozen_string_literal: true

module Uex
  class CommodityPriceSyncer
    include Uex::PriceSnapshot

    ITEM_TYPE = "Commodity"
    TERMINAL_TYPE = "commodity"

    Result = Struct.new(:created, :updated, :removed, :skipped_removals, :unknown) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} " \
          "skipped_removals=#{skipped_removals} unknown=#{unknown.size}"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      terminals = require_rows(
        :terminals,
        @client.terminals.select { |terminal| terminal["type"] == TERMINAL_TYPE }
      ).index_by { |terminal| terminal["id"] }
      prices = require_rows(:commodity_prices, @client.commodity_prices)

      # The mapper has already resolved names to ids, so the price feed needs no
      # matching of its own -- a commodity we never mapped simply has no entry.
      commodities = Commodity.where.not(uex_id: nil).select(:id, :uex_id).index_by(&:uex_id)
      unknown = {}

      desired = collect(prices, commodities:, terminals:, unknown:)
      counts = persist_prices(desired, live: terminals.values.map { |terminal| terminal["name"].to_s.strip }.to_set)

      Result.new(
        created: counts.created,
        updated: counts.updated,
        removed: counts.removed,
        skipped_removals: counts.skipped_removals,
        unknown: unknown.values
      )
    end

    private def collect(rows, commodities:, terminals:, unknown:)
      rows.each_with_object({}) do |row, result|
        terminal = terminals[row["id_terminal"]]
        next if terminal.blank?

        location = terminal["name"].to_s.strip
        next if location.blank?

        commodity = commodities[row["id_commodity"]]

        if commodity.blank?
          unknown[row["id_commodity"]] ||= row
          next
        end

        # UEX writes prices from the player's side: what they pay is price_buy,
        # what they receive is price_sell. Ours is shop-perspective, the way
        # ItemPrice is read everywhere else, so the two swap over.
        add(result, row["price_buy"], commodity:, location:, terminal:, price_type: "sell")
        add(result, row["price_sell"], commodity:, location:, terminal:, price_type: "buy")
      end
    end

    private def add(result, value, commodity:, location:, terminal:, price_type:)
      price = value.to_d
      return if price <= 0

      attributes = {
        item_type: ITEM_TYPE,
        item_id: commodity.id,
        price_type:,
        location:,
        time_range: nil,
        location_url: web_url(terminal["contact_url"]),
        price:
      }

      key = attributes.values_at(:item_id, :price_type, :location, :time_range)
      existing = result[key]

      return result[key] = attributes if existing.blank?

      # Two UEX terminals can collapse onto one location string, and which of the
      # pair to keep depends on the direction: of two shops selling the same
      # cargo the player wants the cheaper, of two buying it the better paid.
      better = (price_type == "sell") ? price < existing[:price] : price > existing[:price]

      result[key] = attributes if better
    end

    # Deliberately free of the sync counts: GithubIssueCreator dedupes on a
    # digest of the body, and prices move every day, so anything volatile in
    # here would open a fresh issue on every run.
    def self.github_issue_body(result)
      lines = ["## Priced UEX Commodities We Do Not Carry (#{result.unknown.size})", ""]
      lines << "UEX prices these at a commodity terminal but they resolve to no `Commodity`,"
      lines << "so the prices are dropped. Either the game files do not declare them or"
      lines << "`Uex::CommodityMatcher::MAPPINGS` is missing an entry."
      lines << ""

      result.unknown.each do |row|
        lines << "- **#{row["commodity_name"]}** — UEX id `#{row["id_commodity"]}`"
      end

      lines.join("\n")
    end
  end
end
