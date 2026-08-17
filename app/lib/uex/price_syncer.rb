# frozen_string_literal: true

module Uex
  class PriceSyncer
    include Uex::PriceSnapshot

    ITEM_TYPE = "Model"
    TERMINAL_TYPES = %w[vehicle_buy vehicle_rent].freeze

    # UEX carries a single rental row per (vehicle, terminal) with no period
    # field. It is the 1-day rate: in game the Avenger Titan rents at 27,165 /
    # 71,308 / 142,616 / 509,344 for 1 / 3 / 7 / 30 days, and UEX reports 27,165.
    RENTAL_TIME_RANGE = "1-day"

    # Stamped on the paper-trail version so a repriced model reads apart from an
    # admin having typed the figure in by hand.
    REPRICE_REASON = "uex_price_sync"

    Result = Struct.new(:created, :updated, :removed, :skipped_removals, :repriced, :unmatched) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} " \
          "skipped_removals=#{skipped_removals} repriced=#{repriced} unmatched=#{unmatched.size}"
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

      result = persist(
        desired,
        live: terminals.values.map { |terminal| terminal["name"].to_s.strip }.to_set,
        unmatched: matcher.misses
      )

      result.repriced = reprice_models
      result
    end

    # `models.price` is the figure the ship list sorts and filters on and the one
    # fleet value totals add up, and nothing kept it in step with the shops — it
    # was hand-entered per model. The cheapest sell price is what a player
    # actually pays, so that is what it now tracks.
    #
    # Models UEX prices nothing for keep whatever they hold: no feed row is not
    # the same as not for sale, and a stale figure still beats none for sorting.
    private def reprice_models
      cheapest = ItemPrice.where(item_type: ITEM_TYPE, price_type: "sell")
        .group(:item_id)
        .minimum(:price)

      repriced = 0

      Model.where(id: cheapest.keys).find_each do |model|
        price = cheapest[model.id]
        next if model.price == price

        model.update!(price:, update_reason: REPRICE_REASON)
        repriced += 1
      end

      repriced
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
          location_url: web_url(terminal["contact_url"]),
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

    private def persist(desired, live:, unmatched:)
      counts = persist_prices(desired, live:)

      Result.new(
        created: counts.created,
        updated: counts.updated,
        removed: counts.removed,
        skipped_removals: counts.skipped_removals,
        unmatched: unmatched.uniq { |vehicle| vehicle["id"] }
      )
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
