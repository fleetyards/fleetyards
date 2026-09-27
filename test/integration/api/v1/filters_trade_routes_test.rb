# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersTradeRoutesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/trade-routes/star-systems" do
    get("Trade Route Star System Filters") do
      operationId "tradeRouteStarSystemsFilters"
      tags "TradeRoutesFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "feature unavailable") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/filters/trade-routes/terminals" do
    get("Trade Route Terminal Filters") do
      operationId "tradeRouteTerminalsFilters"
      tags "TradeRoutesFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "feature unavailable") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/filters/trade-routes/commodities" do
    get("Trade Route Commodity Filters") do
      operationId "tradeRouteCommoditiesFilters"
      tags "TradeRoutesFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "feature unavailable") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("trade_routes")

    @arc = create(:terminal, name: "Admin - ARC-L1", star_system: "Stanton")
    @ruin = create(:terminal, name: "Admin - Ruin Station", star_system: "Pyro")
    @closed = create(:terminal, name: "Admin - Old Outpost", star_system: "Nyx", available: false)
    create(:terminal, name: "Lonely Terminal", star_system: "Nyx")

    commodity = create(:commodity, name: "Gold")
    create(:commodity, name: "Untraded")
    [[@arc, @ruin], [@ruin, @closed]].each do |origin, destination|
      TradeRoute.create!(commodity:, origin_terminal: origin, destination_terminal: destination,
        price_origin: 10, price_destination: 20, container_sizes: [1])
    end
  end

  test "GET /filters/trade-routes/star-systems lists the systems an available route touches" do
    assert_api_response :get, 200, api_path: "/filters/trade-routes/star-systems" do
      assert_equal %w[Pyro Stanton], parsed_body.pluck("value")
    end
  end

  test "GET /filters/trade-routes/terminals lists the available terminals a route uses" do
    assert_api_response :get, 200, api_path: "/filters/trade-routes/terminals" do
      assert_equal [@arc.id, @ruin.id], parsed_body.pluck("value")
      assert_equal ["Admin - ARC-L1", "Admin - Ruin Station"], parsed_body.pluck("label")
      assert_equal "Stanton", parsed_body.first["category"]
    end
  end

  test "GET /filters/trade-routes/commodities lists the commodities a route carries" do
    assert_api_response :get, 200, api_path: "/filters/trade-routes/commodities" do
      assert_equal ["Gold"], parsed_body.pluck("label")
      assert_equal ["gold"], parsed_body.pluck("value")
    end
  end

  test "GET /filters/trade-routes/terminals is unavailable while the feature is off" do
    Flipper.disable("trade_routes")

    assert_api_response :get, 403, api_path: "/filters/trade-routes/terminals"
  end
end
