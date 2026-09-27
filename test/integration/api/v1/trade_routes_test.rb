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
      assert_equal [48, 1440], low_stock.values_at("loadableScu", "profitPerRun")
      assert_equal [64, 1280], small_crates.values_at("loadableScu", "profitPerRun")
      assert_equal 6400, best["investment"]
    end
  end

  test "GET /trade-routes ranks a ship's runs by profit per run by default" do
    # 25 per SCU on a full 64 SCU hold earns 1,600; the low-stock route makes
    # 30 per SCU but only 48 SCU of it, 1,440.
    full_hold = create_route(@agricium, @area18, @arc, price_origin: 10, price_destination: 35)

    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug, "commoditySlugIn" => [@agricium.slug]}} do
      assert_equal [full_hold.id, @low_stock.id], ids
    end
  end

  test "GET /trade-routes ranks the runs a ship that can't land can fly first" do
    hull = station_only_ship

    assert_api_response :get, 200, params: {q: {"modelSlug" => hull.slug}} do
      assert_equal [@low_stock.id, @best_margin.id, @small_crates.id], ids
      assert_equal [nil, "destination", "origin"], parsed_body["items"].pluck("unflyableReason")
    end
  end

  test "GET /trade-routes keeps the figures of a run a ship can't fly" do
    hull = station_only_ship

    assert_api_response :get, 200, params: {q: {"modelSlug" => hull.slug}} do
      run = parsed_body["items"].find { |item| item["id"] == @best_margin.id }
      assert_equal [64, 3200], run.values_at("loadableScu", "profitPerRun")
    end
  end

  test "GET /trade-routes marks a run with both ends on a surface" do
    outpost = create(:terminal, name: "Shubin SM0-10", star_system: "Stanton", outpost: "Shubin SM0-10")
    both = create_route(@gold, @area18, outpost, price_origin: 100, price_destination: 110)

    assert_api_response :get, 200, params: {q: {"modelSlug" => station_only_ship.slug}} do
      assert_equal "both", parsed_body["items"].find { |item| item["id"] == both.id }["unflyableReason"]
    end
  end

  test "GET /trade-routes picks a purchase's best destination among those a ship can fly" do
    to_station = create_route(@gold, @arc, @ruin, price_origin: 100, price_destination: 130, distance: 20)

    assert_api_response :get, 200, params: {q: {"modelSlug" => station_only_ship.slug, "grouped" => true}} do
      assert_includes ids, to_station.id
      assert_not_includes ids, @best_margin.id
    end
  end

  test "GET /trade-routes marks nothing for a ship that lands" do
    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug}} do
      assert(parsed_body["items"].all? { |item| item["unflyableReason"].nil? })
    end
  end

  test "GET /trade-routes says what limits each load" do
    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug}} do
      best, low_stock = parsed_body["items"]
      assert_equal "hold", best["loadLimit"]
      assert_equal "stock", low_stock["loadLimit"]
    end
  end

  test "GET /trade-routes loads stock only in whole crates of the sizes allowed" do
    @low_stock.update!(scu_origin: 5)

    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug}} do
      route = parsed_body["items"].find { |item| item["id"] == @low_stock.id }
      assert_equal [0, "stock", 0], route.values_at("loadableScu", "loadLimit", "profitPerRun")
    end
  end

  test "GET /trade-routes caps the load at what the budget buys" do
    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug, "budget" => 3000}} do
      best = parsed_body["items"].find { |item| item["id"] == @best_margin.id }
      assert_equal [30, "budget", 1500], best.values_at("loadableScu", "loadLimit", "profitPerRun")
      assert_equal 3000, best["investment"]
    end
  end

  test "GET /trade-routes leaves out routes with a price older than the maximum age" do
    @low_stock.update!(origin_price_updated_at: 5.days.ago)

    assert_api_response :get, 200, params: {q: {"maxPriceAgeHours" => 72}} do
      assert_equal [@best_margin.id, @small_crates.id], ids
    end
  end

  test "GET /trade-routes groups routes by commodity and buy terminal" do
    other = create_route(@gold, @arc, @ruin, price_origin: 100, price_destination: 130, distance: 20)

    assert_api_response :get, 200, params: {q: {"modelSlug" => @ship.slug, "grouped" => true}} do
      assert_equal [@best_margin.id, @low_stock.id, @small_crates.id], ids
      assert_equal 1, parsed_body["items"].first["otherDestinations"]
      assert_equal 0, parsed_body["items"].last["otherDestinations"]
      assert_not_includes ids, other.id
    end
  end

  test "GET /trade-routes keeps a group's best destination by the requested sort" do
    closer = create_route(@gold, @arc, @ruin, price_origin: 100, price_destination: 130, distance: 5)

    assert_api_response :get, 200, params: {q: {"grouped" => true, "sorts" => ["distance asc"]}} do
      assert_includes ids, closer.id
      assert_not_includes ids, @best_margin.id
    end
  end

  test "GET /trade-routes counts grouped rows for pagination" do
    create_route(@gold, @arc, @ruin, price_origin: 100, price_destination: 130, distance: 20)

    assert_api_response :get, 200, params: {q: {"grouped" => true}} do
      assert_equal 3, parsed_body.dig("meta", "pagination", "totalCount")
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

  # The same 64 SCU hold as the ship in setup, on a ship that can't land.
  private def station_only_ship
    ship = create(:model, name: "Hull C", can_land_on_planets: false)
    hold = create(:cargo_hold, parent: ship, capacity_scu: 64, max_container_size_scu: 32)
    {32 => 2, 16 => 4, 8 => 8, 4 => 16, 2 => 32, 1 => 64}.each do |size, quantity|
      CargoHoldContainerCapacity.create!(cargo_hold: hold, container_size_scu: size, max_quantity: quantity)
    end
    ship
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
