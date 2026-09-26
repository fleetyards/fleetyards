# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class TradeRouteSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      TradeRoute.delete_all
      Terminal.delete_all
      Commodity.delete_all
      @commodities = create_uex_priced_commodities
      Uex::TerminalSyncer.new(client: uex_client_stub).run
      @pauses = []
    end

    test "#run stores the profitable routes between terminals we know" do
      result = sync

      assert_equal 3, result.routes
      assert_equal 2, result.commodities
      assert_equal [[104, 105], [105, 102]], routes_for(@commodities[:gold])
      assert_equal [[102, 104]], routes_for(@commodities[:agricium_ore])
    end

    test "#run drops routes that lose money or have nothing to carry" do
      result = sync

      assert_equal 2, result.unprofitable
    end

    test "#run drops routes to a terminal we do not know" do
      result = sync

      assert_equal 1, result.unknown_terminals
    end

    test "#run stores prices, stock, container sizes and distance" do
      sync

      route = TradeRoute.find_by!(origin_terminal: terminal(104), destination_terminal: terminal(105))

      assert_equal 27_527, route.price_origin
      assert_equal 29_000, route.price_destination
      assert_equal 1473, route.profit_per_scu
      assert_equal 1200, route.scu_origin
      assert_equal 80, route.scu_destination
      assert_equal [1, 2, 4], route.container_sizes_origin
      assert_equal [1, 2, 4, 8], route.container_sizes_destination
      assert_equal 3, route.distance
    end

    test "#run dates each end from the price feed" do
      sync

      route = TradeRoute.find_by!(origin_terminal: terminal(104), destination_terminal: terminal(105))

      assert_equal Time.zone.at(1766170000), route.origin_price_updated_at
      assert_equal Time.zone.at(1766171000), route.destination_price_updated_at
    end

    test "#run replaces the routes of a commodity on the next run" do
      sync
      rows = uex_fixture("commodities_routes").reject { |row| row["id"] == 1 }

      sync(commodity_routes: rows)

      assert_equal [[104, 105]], routes_for(@commodities[:gold])
    end

    test "#run keeps the routes of a commodity whose request failed" do
      sync
      client = uex_client_stub
      client.stubs(:commodity_routes).with(33).raises(Uex::Error, "timeout")

      result = Uex::TradeRouteSyncer.new(client:, pause: ->(_) {}).run

      assert_equal ["Gold"], result.failed.map(&:name)
      assert_equal [[104, 105], [105, 102]], routes_for(@commodities[:gold])
    end

    test "#run raises when every request failed" do
      client = uex_client_stub
      client.stubs(:commodity_routes).raises(Uex::Error, "down")

      assert_raises(Uex::Error) { Uex::TradeRouteSyncer.new(client:, pause: ->(_) {}).run }
    end

    test "#run removes the routes of a commodity that lost its UEX mapping" do
      sync
      @commodities[:agricium_ore].update!(uex_id: nil)

      sync

      assert_empty routes_for(@commodities[:agricium_ore])
    end

    test "#run pauses between requests" do
      sync

      assert_equal [Uex::TradeRouteSyncer::REQUEST_INTERVAL], @pauses
    end

    private def sync(**overrides)
      Uex::TradeRouteSyncer.new(client: uex_client_stub(overrides), pause: ->(seconds) { @pauses << seconds }).run
    end

    private def terminal(uex_id)
      Terminal.find_by!(uex_id:)
    end

    private def routes_for(commodity)
      TradeRoute.where(commodity:).includes(:origin_terminal, :destination_terminal).map do |route|
        [route.origin_terminal.uex_id, route.destination_terminal.uex_id]
      end.sort
    end
  end
end
