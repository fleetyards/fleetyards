# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TradeRoutesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/trade-routes" do
    get("Trade routes list") do
      operationId "tradeRoutes"
      tags "TradeRoutes"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: TradeRoute.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::TradeRouteQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::TradeRoutes::TradeRoutes
      end

      response(403, "feature unavailable") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("trade_routes")

    @arc = create(:terminal, name: "Admin - ARC-L1", star_system: "Stanton", space_station: "ARC-L1 Wide Forest Station")
    @area18 = create(:terminal, name: "TDD - Area 18", star_system: "Stanton", city: "Area 18")
    @ruin = create(:terminal, name: "Admin - Ruin Station", star_system: "Pyro", space_station: "Ruin Station")

    @gold = create(:commodity, name: "Gold")
    @agricium = create(:commodity, name: "Agricium")

    @best_margin = create_route(@gold, @arc, @area18, price_origin: 100, price_destination: 150, distance: 40)
    @small_crates = create_route(@gold, @area18, @ruin, price_origin: 100, price_destination: 120,
      container_sizes: [1, 2], distance: 0)
    @low_stock = create_route(@agricium, @arc, @ruin, price_origin: 10, price_destination: 40,
      scu_origin: 50, container_sizes: [8, 16], distance: 100)

    # 64 SCU in one hold, whichever crate size fills it.
    @ship = create(:model, name: "Freelancer")
    @hold = create(:cargo_hold, parent: @ship, capacity_scu: 64, max_container_size_scu: 32)
    {32 => 2, 16 => 4, 8 => 8, 4 => 16, 2 => 32, 1 => 64}.each do |size, quantity|
      CargoHoldContainerCapacity.create!(cargo_hold: @hold, container_size_scu: size, max_quantity: quantity)
    end
  end

  test "GET /trade-routes ranks by profit per SCU without a ship" do
    assert_api_response :get, 200 do
      assert_equal [@best_margin.id, @low_stock.id, @small_crates.id], ids
      assert_nil parsed_body["items"].first["loadableScu"]
    end
  end

  test "GET /trade-routes names both terminals and the commodity" do
    assert_api_response :get, 200 do
      route = parsed_body["items"].first

      assert_equal "Gold", route.dig("commodity", "name")
      assert_equal "ARC-L1 Wide Forest Station", route.dig("originTerminal", "spaceStation")
      assert_equal "Area 18", route.dig("destinationTerminal", "city")
      assert_equal 50, route["profitPerScu"]
    end
  end

  test "GET /trade-routes ranks by profit per run for a ship" do
    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug}} do
      assert_equal [@best_margin.id, @low_stock.id, @small_crates.id], ids

      best, low_stock, small_crates = parsed_body["items"]
      assert_equal [64, 3200], best.values_at("loadableScu", "profitPerRun")
      assert_equal [50, 1500], low_stock.values_at("loadableScu", "profitPerRun")
      assert_equal [64, 1280], small_crates.values_at("loadableScu", "profitPerRun")
      assert_equal 6400, best["investment"]
    end
  end

  test "GET /trade-routes loads only the crate sizes both terminals accept" do
    @hold.cargo_hold_container_capacities.where(container_size_scu: [1, 2]).update_all(max_quantity: 0)

    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug}} do
      route = parsed_body["items"].find { |item| item["id"] == @small_crates.id }
      assert_equal 0, route["loadableScu"]
    end
  end

  test "GET /trade-routes sorts by profit per distance and leaves a zero distance last" do
    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug, "sorts" => ["profitPerDistance desc"]}} do
      assert_equal [@best_margin.id, @low_stock.id, @small_crates.id], ids
      assert_nil parsed_body["items"].last["profitPerDistance"]
    end
  end

  test "GET /trade-routes ignores a ship-only sort without a ship" do
    assert_api_response :get, 200, params: {q: {"sorts" => ["profitPerRun desc"]}} do
      assert_equal [@best_margin.id, @low_stock.id, @small_crates.id], ids
    end
  end

  test "GET /trade-routes filters by destination system" do
    assert_api_response :get, 200, params: {q: {"destinationTerminalStarSystemIn" => ["Pyro"]}} do
      assert_equal [@low_stock.id, @small_crates.id], ids
    end
  end

  test "GET /trade-routes filters by origin terminal" do
    assert_api_response :get, 200, params: {q: {"originTerminalIdIn" => [@area18.id]}} do
      assert_equal [@small_crates.id], ids
    end
  end

  test "GET /trade-routes filters by commodity" do
    assert_api_response :get, 200, params: {q: {"commoditySlugIn" => [@agricium.slug]}} do
      assert_equal [@low_stock.id], ids
    end
  end

  test "GET /trade-routes leaves out routes touching an unavailable terminal" do
    @ruin.update!(available: false)

    assert_api_response :get, 200 do
      assert_equal [@best_margin.id], ids
    end
  end

  test "GET /trade-routes is unavailable while the feature is off" do
    Flipper.disable("trade_routes")

    assert_api_response :get, 403
  end

  private def ids
    parsed_body["items"].pluck("id")
  end

  private def create_route(commodity, origin, destination, price_origin:, price_destination:,
    scu_origin: 1000, scu_destination: 1000, container_sizes: CargoHoldContainerCapacity::CONTAINER_SIZES, distance: nil)
    TradeRoute.create!(
      commodity:, origin_terminal: origin, destination_terminal: destination,
      price_origin:, price_destination:, scu_origin:, scu_destination:,
      container_sizes_origin: container_sizes, container_sizes_destination: container_sizes, container_sizes:,
      distance:, origin_price_updated_at: 2.hours.ago, destination_price_updated_at: 3.hours.ago
    )
  end
end
