# frozen_string_literal: true

module Uex
  class PriceSyncer
    ITEM_TYPE = "Model"
    TERMINAL_TYPES = %w[vehicle_buy vehicle_rent].freeze

    # UEX carries a single rental row per (vehicle, terminal) with no period
    # field. It is the 1-day rate: in game the Avenger Titan rents at 27,165 /
    # 71,308 / 142,616 / 509,344 for 1 / 3 / 7 / 30 days, and UEX reports 27,165.
    RENTAL_TIME_RANGE = "1-day"

    # How much of a terminal's stock it must still list before we believe its
    # omissions. A shop dropping over half its vehicles between two daily runs is
    # not plausible churn; a feed that came back short looks exactly like that.
    MIN_TERMINAL_RETENTION = 0.5

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

    private def persist(desired, live:, unmatched:)
      created = 0
      updated = 0
      removed = 0
      skipped_removals = 0

      ItemPrice.transaction do
        held = ItemPrice.where(item_type: ITEM_TYPE).to_a
        held_per_location = held.group_by(&:location).transform_values(&:size)
        listed_per_location = desired.values.group_by { |row| row[:location] }.transform_values(&:size)

        # Whatever is left in here once every desired row has claimed its match
        # is a location UEX no longer lists.
        unclaimed = held.index_by do |item_price|
          [item_price.item_id, item_price.price_type, item_price.location, item_price.time_range]
        end

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
          deletable?(item_price.location, listed: listed_per_location, held: held_per_location, live:)
        end

        # Upserts have already applied either way, so fresh prices still land and
        # only the destructive half is held back. A later whole snapshot reconciles.
        skipped_removals = ambiguous.size
        report_skipped_removals(ambiguous, held.size) if ambiguous.any?

        removed = ItemPrice.where(id: deletable.map(&:id)).destroy_all.size
      end

      Result.new(
        created:, updated:, removed:, skipped_removals:,
        unmatched: unmatched.uniq { |vehicle| vehicle["id"] }
      )
    end

    # Decided per terminal, because that is the only granularity at which the
    # question is answerable. A terminal gone from the terminals feed has closed,
    # so its rows go. Otherwise the test is whether it reported at anything like
    # its usual volume: a shop discontinuing a ship or two still lists the rest,
    # whereas a truncated feed shows up as a terminal that suddenly lists a
    # fraction of what we hold for it — or nothing at all. Below the retention
    # floor we keep its rows and report rather than guess.
    private def deletable?(location, listed:, held:, live:)
      return true if live.exclude?(location)

      listed.fetch(location, 0) >= held.fetch(location, 0) * MIN_TERMINAL_RETENTION
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
