# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryStockShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    get("Fleet Inventory Stock Position") do
      operationId "fleetInventoryStockItem"
      tags "FleetInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::InventoryStockPosition
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @inventory = create(:fleet_inventory, fleet: @fleet)

    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium",
      category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium",
      category: :commodity, quantity: 30, unit: :scu, entry_type: :withdrawal)

    @slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")
  end

  test "GET /inventories/:slug/stock/:slug rolls up the position" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug} do
      assert_equal "Quantanium", parsed_body["name"]
      assert_equal 70.0, parsed_body["netQuantity"]
      assert_equal 2, parsed_body["entriesCount"]
    end
  end

  test "GET /inventories/:slug/stock/:slug returns 404 for an unknown position" do
    sign_in @admin

    assert_api_response :get, 404,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: "nope--commodity--scu"}
  end

  test "GET /inventories/:slug/stock/:slug returns 401 when not signed in" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug}
  end
end
