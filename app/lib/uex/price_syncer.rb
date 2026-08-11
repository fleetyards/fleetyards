# frozen_string_literal: true

module Uex
  class PriceSyncer
    ITEM_TYPE = "Model"
    TERMINAL_TYPES = %w[vehicle_buy vehicle_rent].freeze

    # UEX carries a single rental row per (vehicle, terminal) with no period
    # field. It is the 1-day rate: in game the Avenger Titan rents at 27,165 /
    # 71,308 / 142,616 / 509,344 for 1 / 3 / 7 / 30 days, and UEX reports 27,165.
    RENTAL_TIME_RANGE = "1-day"

    # Backstop behind the per-terminal rule below, for the one case it cannot
    # judge: terminals that report, but report short. A run that would still drop
    # more than this share of the prices we hold is treated as a bad snapshot
    # rather than a mass closure. Legitimate churn is a terminal or two closing —
    # the largest vehicle terminal is well under a fifth of all rows — so this
    # leaves ample headroom.
    MAX_REMOVAL_RATIO = 0.5

    Result = Struct.new(:created, :updated, :removed, :skipped_removals, :unmatched) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} " \
          "skipped_removals=#{skipped_removals} unmatched=#{unmatched.size}"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      vehicles = require_rows(:vehicles, @client.vehicles).index_by { |vehicle| vehicle["id"] }
      terminals = require_rows(
        :terminals,
        @client.terminals.select { |terminal| TERMINAL_TYPES.include?(terminal["type"]) }
      ).index_by { |terminal| terminal["id"] }
      purchases = require_rows(:vehicle_purchase_prices, @client.vehicle_purchase_prices)
      rentals = require_rows(:vehicle_rental_prices, @client.vehicle_rental_prices)
      matcher = Uex::VehicleMatcher.new

      desired = collect(
        purchases,
        vehicles:, terminals:, matcher:,
        price_key: "price_buy",
        # Ours is shop-perspective: `sell` means the shop sells it, which is what
        # Model#sold_at and the "Sold at?" label read. UEX purchase prices are
        # player-perspective, so they map to `sell`, not `buy`.
        price_type: "sell",
        time_range: nil
      )

      desired.merge!(
        collect(
          rentals,
          vehicles:, terminals:, matcher:,
          price_key: "price_rent",
          price_type: "rental",
          time_range: RENTAL_TIME_RANGE
        )
      )

      persist(
        desired,
        reported: locations_in(purchases + rentals, terminals),
        live: terminals.values.map { |terminal| terminal["name"].to_s.strip }.to_set,
        unmatched: matcher.misses
      )
    end

    # The terminal names this snapshot actually priced something at, taken from
    # the raw rows so a terminal that only listed vehicles we cannot match still
    # counts as having reported.
    private def locations_in(rows, terminals)
      rows.filter_map { |row| terminals[row["id_terminal"]]&.dig("name")&.strip.presence }.to_set
    end

    private def collect(rows, vehicles:, terminals:, matcher:, price_key:, price_type:, time_range:)
      rows.each_with_object({}) do |row, result|
        price = row[price_key].to_d
        next if price <= 0

        vehicle = vehicles[row["id_vehicle"]]
        terminal = terminals[row["id_terminal"]]
        next if vehicle.blank? || terminal.blank?

        location = terminal["name"].to_s.strip
        next if location.blank?

        model = matcher.match(vehicle)
        next if model.blank?

        attributes = {
          item_type: ITEM_TYPE,
          item_id: model.id,
          price_type:,
          location:,
          time_range:,
          location_url: terminal["contact_url"].presence,
          price:
        }

        key = attributes.values_at(:item_id, :price_type, :location, :time_range)

        # Two UEX terminals can collapse onto one location string. Model#sold_at
        # sorts by price then uniqs by location, so the cheapest is the one that
        # would surface anyway.
        existing = result[key]
        result[key] = attributes if existing.blank? || price < existing[:price]
      end
    end

    # None of the four feeds is ever legitimately empty. An empty one still
    # arrives as HTTP 200 with status "ok", and taking it at face value would read
    # as "every location closed" and delete the lot.
    private def require_rows(feed, rows)
      return rows if rows.present?

      raise Uex::Error, "UEX returned no usable rows for #{feed}; refusing to sync a snapshot that would delete live prices"
    end

    private def persist(desired, reported:, live:, unmatched:)
      created = 0
      updated = 0
      removed = 0
      skipped_removals = 0

      ItemPrice.transaction do
        # Whatever is left in here once every desired row has claimed its match
        # is a location UEX no longer lists.
        unclaimed = ItemPrice.where(item_type: ITEM_TYPE).index_by do |item_price|
          [item_price.item_id, item_price.price_type, item_price.location, item_price.time_range]
        end
        held_before = unclaimed.size

        desired.each do |key, attributes|
          item_price = unclaimed.delete(key)

          if item_price.blank?
            ItemPrice.create!(attributes)
            created += 1
            next
          end

          item_price.assign_attributes(attributes.slice(:price, :location_url))
          next unless item_price.changed?

          item_price.save!
          updated += 1
        end

        deletable, ambiguous = unclaimed.values.partition do |item_price|
          deletable?(item_price.location, reported:, live:)
        end

        if wholesale_removal?(deletable.size, held_before)
          ambiguous += deletable
          deletable = []
        end

        # Upserts have already applied either way, so fresh prices still land and
        # only the destructive half is held back. A later whole snapshot reconciles.
        skipped_removals = ambiguous.size
        report_skipped_removals(ambiguous, held_before) if ambiguous.any?

        removed = ItemPrice.where(id: deletable.map(&:id)).destroy_all.size
      end

      Result.new(
        created:, updated:, removed:, skipped_removals:,
        unmatched: unmatched.uniq { |vehicle| vehicle["id"] }
      )
    end

    # A terminal that priced anything in this snapshot is authoritative for its
    # own inventory, so one of our rows it did not list really is gone. A terminal
    # that priced nothing is ambiguous — either every ship left the shop or the
    # feed came back short — and only the terminals feed can settle it: if the
    # shop is gone from there too, the rows go; otherwise they stay.
    private def deletable?(location, reported:, live:)
      reported.include?(location) || live.exclude?(location)
    end

    private def wholesale_removal?(pending, held_before)
      held_before.positive? && pending > held_before * MAX_REMOVAL_RATIO
    end

    private def report_skipped_removals(preserved, held_before)
      message = "UEX snapshot omitted #{preserved.size} of #{held_before} model prices at " \
        "#{preserved.map(&:location).uniq.sort.join(", ")}; kept them and applied updates only"

      Rails.logger.warn("[Uex::PriceSyncer] #{message}")
      Appsignal.report_error(Uex::Error.new(message))
    end

    # Deliberately free of the sync counts: GithubIssueCreator dedupes on a
    # digest of the body, and prices move every day, so anything volatile in
    # here would open a fresh issue on every run.
    def self.github_issue_body(result)
      lines = ["## Unmatched UEX Vehicles (#{result.unmatched.size})", ""]
      lines << "These UEX vehicles carry a price but do not resolve to a `Model`."
      lines << "Add them to `Uex::VehicleMatcher::MAPPINGS`."
      lines << ""

      result.unmatched.each do |vehicle|
        lines << "- **#{vehicle["name_full"].presence || vehicle["name"]}** — `#{vehicle["slug"]}`"
      end

      lines.join("\n")
    end
  end
end
