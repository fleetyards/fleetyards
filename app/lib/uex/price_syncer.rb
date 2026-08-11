# frozen_string_literal: true

module Uex
  class PriceSyncer
    ITEM_TYPE = "Model"
    TERMINAL_TYPES = %w[vehicle_buy vehicle_rent].freeze

    # UEX carries a single rental row per (vehicle, terminal) with no period
    # field. It is the 1-day rate: in game the Avenger Titan rents at 27,165 /
    # 71,308 / 142,616 / 509,344 for 1 / 3 / 7 / 30 days, and UEX reports 27,165.
    RENTAL_TIME_RANGE = "1-day"

    Result = Struct.new(:created, :updated, :removed, :unmatched) do
      def to_s
        "created=#{created} updated=#{updated} removed=#{removed} unmatched=#{unmatched.size}"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      vehicles = @client.vehicles.index_by { |vehicle| vehicle["id"] }
      terminals = @client.terminals
        .select { |terminal| TERMINAL_TYPES.include?(terminal["type"]) }
        .index_by { |terminal| terminal["id"] }
      matcher = Uex::VehicleMatcher.new

      desired = collect(
        @client.vehicle_purchase_prices,
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
          @client.vehicle_rental_prices,
          vehicles:, terminals:, matcher:,
          price_key: "price_rent",
          price_type: "rental",
          time_range: RENTAL_TIME_RANGE
        )
      )

      persist(desired, unmatched: matcher.misses)
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

    private def persist(desired, unmatched:)
      created = 0
      updated = 0
      removed = 0

      ItemPrice.transaction do
        # Whatever is left in here once every desired row has claimed its match
        # is a location UEX no longer lists.
        unclaimed = ItemPrice.where(item_type: ITEM_TYPE).index_by do |item_price|
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

        removed = ItemPrice.where(id: unclaimed.values.map(&:id)).destroy_all.size
      end

      Result.new(created:, updated:, removed:, unmatched: unmatched.uniq { |vehicle| vehicle["id"] })
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
