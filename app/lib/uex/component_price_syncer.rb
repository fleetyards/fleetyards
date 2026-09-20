# frozen_string_literal: true

module Uex
  class ComponentPriceSyncer
    include Uex::PriceSnapshot

    ITEM_TYPE = "Component"
    TERMINAL_TYPE = "item"

    # The UEX sections that hold things a ship carries. Everything else it
    # prices -- clothing, food, FPS weapons, helmets -- is not a component and
    # never will be, so an unmatched item from one of those is noise rather than
    # a gap. Nineteen of UEX's twenty-four thousand price rows in the other
    # sections would otherwise drown the one report that matters.
    COMPONENT_SECTIONS = [
      "Vehicle Weapons", "Systems", "Utility", "Propulsion", "Avionics", "Module", "Liveries"
    ].freeze

    # `unknown` is split on purpose. A UEX item in a component section that we
    # cannot place is a gap somebody should look at -- a part renamed by a patch
    # loses its prices exactly this way. One in Clothing or Foods is neither a
    # gap nor a component, and the two must not be counted together.
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
      sections = require_rows(:categories, @client.item_categories)
        .to_h { |category| [category["id"], category["section"]] }

      matcher = Uex::ComponentMatcher.new

      desired = collect(prices, matcher:, terminals:)
      counts = persist_prices(desired, live: terminals.values.map { |terminal| terminal["name"].to_s.strip }.to_set)

      record_price_history

      unknown, unknown_other = matcher.misses.partition do |row|
        COMPONENT_SECTIONS.include?(sections[row["id_category"]])
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

        component_id =
          if resolved.key?(row["id_item"])
            resolved[row["id_item"]]
          else
            resolved[row["id_item"]] = matcher.match(row)
          end

        next if component_id.blank?

        # UEX writes prices from the player's side: what they pay is price_buy,
        # what they receive is price_sell. Ours is shop-perspective, the way
        # ItemPrice is read everywhere else, so the two swap over.
        add(result, row["price_buy"], component_id:, location:, terminal:, price_type: "sell")
        add(result, row["price_sell"], component_id:, location:, terminal:, price_type: "buy")
      end
    end

    private def add(result, value, component_id:, location:, terminal:, price_type:)
      price = value.to_d
      return if price <= 0

      attributes = {
        item_type: ITEM_TYPE,
        item_id: component_id,
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
      # pair to keep depends on the direction: of two shops selling the same part
      # the player wants the cheaper, of two buying it the better paid.
      better = (price_type == "sell") ? price < existing[:price] : price > existing[:price]

      result[key] = attributes if better
    end

    # Deliberately free of anything that moves on its own. GithubIssueCreator
    # dedupes on a digest of the body, so a line that changes when nothing has
    # actually changed opens a fresh issue every single run -- which is why the
    # counts are absent, and why the personal-gear misses are absent too: UEX
    # adds a pair of trousers most weeks and not one of them is a component.
    # Those live in the import output, which nothing dedupes.
    def self.github_issue_body(result)
      lines = ["## Priced UEX Items We Cannot Place", ""]

      if result.stale_mappings.any?
        lines << "### Mapped to a component that is gone"
        lines << ""
        lines << "`Uex::ComponentMatcher::MAPPINGS` names an `sc_key` the catalogue no longer"
        lines << "carries, so the price is dropped. The entry needs repointing or removing --"
        lines << "until it is, this item is unpriced and the mapping is doing nothing."
        lines << ""
        result.stale_mappings.each do |row, sc_key|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → missing `#{sc_key}`"
        end
        lines << ""
      end

      if result.ambiguous.any?
        lines << "### Named by several components"
        lines << ""
        lines << "The game files carry a row per mount, so these names answer to more than one"
        lines << "component and nothing says which one the shop stocks. They are left unpriced:"
        lines << "guessing would put a shop price on a mount welded to one ship. Add an entry to"
        lines << "`Uex::ComponentMatcher::MAPPINGS` to settle one."
        lines << ""
        result.ambiguous.each do |row, sc_keys|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → `#{sc_keys.join("`, `")}`"
        end
        lines << ""
      end

      if result.unknown.any?
        lines << "### A ship part we cannot place"
        lines << ""
        lines << "UEX files these under a section a ship carries from, and neither `sc_ref` nor"
        lines << "the name reaches a catalogued `Component`. Either the build we are on has"
        lines << "dropped the part, or a patch renamed it and its prices have silently gone with"
        lines << "the old name."
        lines << ""
        result.unknown.each do |row|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}`"
        end
      end

      lines.join("\n")
    end
  end
end
