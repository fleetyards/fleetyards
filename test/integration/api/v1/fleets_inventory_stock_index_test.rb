# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Fleet Inventory Stock") do
      operationId "fleetInventoryStock"
      parameter name: "heldByMe", in: :query, schema: {type: :boolean}, required: false,
        description: "Only the caller's own share"
      tags "FleetInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Logistics::FleetInventoryStockItemsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 50, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Medical Supplies", category: :consumable, quantity: 10, unit: :units, entry_type: :deposit)
  end

  test "GET /inventories/:slug/stock aggregates deposits minus withdrawals" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug} do
      quantanium = parsed_body.find { |d| d["name"] == "Quantanium" }
      assert_equal 120.0, quantanium["netQuantity"]
      medical = parsed_body.find { |d| d["name"] == "Medical Supplies" }
      assert_equal 10.0, medical["netQuantity"]
    end
  end

  test "GET /inventories/:slug/stock returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug}
  end

  test "GET /inventories/:slug/stock with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /inventories/:slug/stock is not found on an officers-only inventory for a plain member" do
    closed = create(:fleet_inventory, :officers_only, fleet: @fleet)
    sign_in @member

    get "/api/v1/fleets/#{@fleet.slug}/inventories/#{closed.slug}/stock"

    assert_response :not_found
  end

  test "GET /inventories/:slug/stock breaks every lot down by holder" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity: 5_000, holder: @member)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity: 2_000, holder: @admin)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity: 500)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug} do
      auec = parsed_body.find { |row| row["name"] == "aUEC" }

      assert_equal 7_500.0, auec["netQuantity"]
      assert_equal [[@member.username, 5_000.0], [@admin.username, 2_000.0], [nil, 500.0]],
        auec["holders"].map { |share| [share.dig("holder", "username"), share["netQuantity"]] }
    end
  end

  test "GET /inventories/:slug/stock?heldByMe=true lists the caller's share only" do
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity: 5_000, holder: @member)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "aUEC", category: :other, unit: :units,
      quantity: 2_000, holder: @admin)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      params: {heldByMe: true} do
      assert_equal [["aUEC", 2_000.0]], parsed_body.map { |row| [row["name"], row["netQuantity"]] }
      assert_equal [@admin.username], parsed_body.first["holders"].map { |share| share.dig("holder", "username") }
    end
  end
end
