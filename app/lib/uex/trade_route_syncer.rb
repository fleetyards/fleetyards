# frozen_string_literal: true

module Uex
  class TradeRouteSyncer
    # UEX allows 120 requests a minute. Half of that leaves room for the other
    # syncers and for a retry.
    REQUEST_INTERVAL = 1.second

    Result = Struct.new(:commodities, :routes, :failed, :unprofitable, :unknown_terminals) do
      def to_s
        "commodities=#{commodities} routes=#{routes} failed=#{failed.size} " \
          "unprofitable=#{unprofitable} unknown_terminals=#{unknown_terminals}"
      end
    end

    def initialize(client: Uex::Client.new, pause: ->(seconds) { sleep(seconds) })
      @client = client
      @pause = pause
    end

    def run
      terminals = Terminal.pluck(:uex_id, :id).to_h
      commodities = Commodity.where.not(uex_id: nil).select(:id, :uex_id, :name).order(:uex_id).to_a
      freshness = price_freshness
      result = Result.new(0, 0, [], 0, 0)

      commodities.each_with_index do |commodity, index|
        @pause.call(REQUEST_INTERVAL) if index.positive?

        rows = begin
          @client.commodity_routes(commodity.uex_id)
        rescue Uex::Error => e
          Rails.logger.warn("[#{self.class.name}] #{commodity.name}: #{e.message}")
          result.failed << commodity
          next
        end

        routes = rows.filter_map { |row| route_attributes(row, commodity:, terminals:, freshness:, result:) }
        replace_routes(commodity, routes)

        result.commodities += 1
        result.routes += routes.size
      end

      raise Uex::Error, "every UEX route request failed; kept the routes we hold" if commodities.any? && result.commodities.zero?

      TradeRoute.where.not(commodity_id: commodities.map(&:id)).delete_all

      result
    end

    private def route_attributes(row, commodity:, terminals:, freshness:, result:)
      price_origin = row["price_origin"].to_d
      price_destination = row["price_destination"].to_d

      if price_origin <= 0 || price_destination <= price_origin || row["scu_reachable"].to_i <= 0
        result.unprofitable += 1
        return
      end

      origin_id = terminals[row["id_terminal_origin"]]
      destination_id = terminals[row["id_terminal_destination"]]

      if origin_id.blank? || destination_id.blank?
        result.unknown_terminals += 1
        return
      end

      {
        commodity_id: commodity.id,
        origin_terminal_id: origin_id,
        destination_terminal_id: destination_id,
        price_origin:,
        price_destination:,
        scu_origin: row["scu_origin"].to_i,
        scu_destination: row["scu_destination"].to_i,
        container_sizes_origin: container_sizes(row["container_sizes_origin"]),
        container_sizes_destination: container_sizes(row["container_sizes_destination"]),
        distance: row["distance"].presence&.to_d,
        origin_price_updated_at: freshness[[row["id_commodity"], row["id_terminal_origin"]]],
        destination_price_updated_at: freshness[[row["id_commodity"], row["id_terminal_destination"]]]
      }
    end

    # Replaced per commodity rather than in one pass, so a request that fails
    # halfway through leaves the other commodities' routes current.
    private def replace_routes(commodity, routes)
      now = Time.current
      rows = routes.uniq { |route| route.values_at(:origin_terminal_id, :destination_terminal_id) }
        .map { |route| route.merge(created_at: now, updated_at: now) }

      TradeRoute.transaction do
        TradeRoute.where(commodity_id: commodity.id).delete_all
        TradeRoute.insert_all(rows) if rows.any?
      end
    end

    # Routes carry no timestamp of their own, while the price rows do. One
    # extra request per run is what tells a reader how old a route's prices are.
    private def price_freshness
      @client.commodity_prices.each_with_object({}) do |row, result|
        next unless row["date_modified"].to_i.positive?

        result[[row["id_commodity"], row["id_terminal"]]] = Time.zone.at(row["date_modified"].to_i)
      end
    end

    private def container_sizes(value)
      value.to_s.split(",").filter_map { |size| Integer(size.strip, exception: false) }.select(&:positive?).sort
    end
  end
end
