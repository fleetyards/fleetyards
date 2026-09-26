# frozen_string_literal: true

module Uex
  # Shop prices off UEX's item feed for one of our catalogues. Subclasses supply
  # ITEM_TYPE, SECTIONS (the UEX sections their catalogue lives in), a matcher
  # and the issue body.
  class ItemPriceSyncer
    include Uex::PriceSnapshot

    TERMINAL_TYPE = "item"
    SECTIONS = [].freeze
    # Categories inside SECTIONS that still hold nothing of this catalogue.
    FOREIGN_CATEGORIES = [].freeze

    # `unknown` is split on purpose. A UEX item in one of our sections that we
    # cannot place is a gap somebody should look at -- an item renamed by a
    # patch loses its prices exactly this way. One from any other section is
    # somebody else's catalogue, and the two must not be counted together.
    Result = Struct.new(
      :created, :updated, :removed, :skipped_removals,
      :unknown, :unknown_other, :ambiguous, :stale_mappings
    ) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} " \
          "skipped_removals=#{skipped_removals} unknown=#{unknown.size} " \
          "unknown_other=#{unknown_other.size} ambiguous=#{ambiguous.size} " \
          "stale_mappings=#{stale_mappings.size}"
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
      prices = require_rows(:item_prices, @client.item_prices)
      categories = require_rows(:categories, @client.item_categories).index_by { |category| category["id"] }

      matcher = build_matcher

      desired = collect(prices, matcher:, terminals:)
      counts = persist_prices(desired, live: terminals.values.map { |terminal| terminal["name"].to_s.strip }.to_set)

      record_price_history

      unknown, unknown_other = matcher.misses.partition do |row|
        category = categories[row["id_category"]] || {}

        self.class::SECTIONS.include?(category["section"]) &&
          self.class::FOREIGN_CATEGORIES.exclude?(category["name"])
      end

      Result.new(
        created: counts.created,
        updated: counts.updated,
        removed: counts.removed,
        skipped_removals: counts.skipped_removals,
        unknown:,
        unknown_other:,
        ambiguous: matcher.ambiguous,
        stale_mappings: matcher.stale_mappings
      )
    end

    private def build_matcher
      raise NotImplementedError
    end

    def self.notification_body(result)
      lines = ["## Synced", "", *PriceSnapshot.notification_lines(result)]
      lines << "- **Priced outside our sections**: #{result.unknown_other.size}, ignored"
      lines << ""

      actionable = result.unknown.any? || result.ambiguous.any? || result.stale_mappings.any?
      lines << (actionable ? github_issue_body(result) : "Every priced UEX item in our sections resolved to one we carry.")

      lines.join("\n")
    end

    # Resolved once per item rather than once per price row: the feed carries a
    # row per terminal, so a gun sold at forty shops would otherwise be matched
    # forty times and reported forty times when it misses.
    private def collect(rows, matcher:, terminals:)
      resolved = {}

      rows.each_with_object({}) do |row, result|
        terminal = terminals[row["id_terminal"]]
        next if terminal.blank?

        location = terminal["name"].to_s.strip
        next if location.blank?

        item_id =
          if resolved.key?(row["id_item"])
            resolved[row["id_item"]]
          else
            resolved[row["id_item"]] = matcher.match(row)
          end

        next if item_id.blank?

        # UEX writes prices from the player's side: what they pay is price_buy,
        # what they receive is price_sell. Ours is shop-perspective, the way
        # ItemPrice is read everywhere else, so the two swap over.
        add(result, row["price_buy"], item_id:, location:, terminal:, price_type: "sell")
        add(result, row["price_sell"], item_id:, location:, terminal:, price_type: "buy")
      end
    end

    private def add(result, value, item_id:, location:, terminal:, price_type:)
      price = value.to_d
      return if price <= 0

      attributes = {
        item_type: self.class::ITEM_TYPE,
        item_id:,
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
      # pair to keep depends on the direction: of two shops selling the same item
      # the player wants the cheaper, of two buying it the better paid.
      better = (price_type == "sell") ? price < existing[:price] : price > existing[:price]

      result[key] = attributes if better
    end
  end
end
