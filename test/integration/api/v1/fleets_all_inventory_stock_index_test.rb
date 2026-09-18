# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsAllInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventory-stock" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet All Inventory Stock") do
      operationId "fleetAllInventoryStock"
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
    @fleet = create(:fleet, admins: [@admin])
    inv1 = create(:fleet_inventory, fleet: @fleet, name: "Mining Ops")
    inv2 = create(:fleet_inventory, fleet: @fleet, name: "Medical Bay")
    create(:fleet_inventory_item, fleet_inventory: inv1, name: "Quantanium", category: :commodity, quantity: 200, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inv2, name: "Med Pens", category: :consumable, quantity: 50, unit: :units, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inv2, name: "Med Pens", category: :consumable, quantity: 10, unit: :units, entry_type: :withdrawal)
  end

  # Matched against the catalogue by id: a position's name is whatever the
  # owner typed, so name-against-name would mis-match and silently miss.
  # `COUNT(DISTINCT)` skips nulls, so a position holding one linked entry and
  # one free-text entry would otherwise claim the link -- and the position's
  # whole quantity with it.
  test "GET inventory-stock stays silent where only some entries name a record" do
    sign_in @admin
    inventory = create(:fleet_inventory, fleet: @fleet, name: "Refinery")
    create(:fleet_inventory_item, fleet_inventory: inventory,
      item: create(:commodity, name: "Iron"),
      name: "Ore", category: :commodity, quantity: 5, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inventory, item: nil,
      name: "Ore", category: :commodity, quantity: 5, unit: :scu, entry_type: :deposit)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil parsed_body.find { |entry| entry["name"] == "Ore" }["item"]
    end
  end

  test "GET fleet inventory-stock names the catalogue record a position points at" do
    sign_in @admin
    iron = create(:commodity, name: "Iron")
    inventory = create(:fleet_inventory, fleet: @fleet, name: "Refinery")
    create(:fleet_inventory_item, fleet_inventory: inventory, item: iron, name: "Iron",
      category: :commodity, quantity: 12, unit: :scu, entry_type: :deposit)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      position = parsed_body.find { |entry| entry["name"] == "Iron" }

      assert_equal iron.id, position["item"]["id"]
      assert_equal "Commodity", position["item"]["type"]
    end
  end

  test "GET fleet inventory-stock stays silent where a position's entries disagree" do
    sign_in @admin
    inventory = create(:fleet_inventory, fleet: @fleet, name: "Refinery")
    create(:fleet_inventory_item, fleet_inventory: inventory, item: create(:commodity, name: "Iron"),
      name: "Ore", category: :commodity, quantity: 5, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inventory, item: create(:commodity, name: "Corundum"),
      name: "Ore", category: :commodity, quantity: 5, unit: :scu, entry_type: :deposit)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil parsed_body.find { |entry| entry["name"] == "Ore" }["item"]
    end
  end

  test "GET /fleets/:slug/inventory-stock aggregates across inventories" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body.length

      med_pens = parsed_body.find { |d| d["name"] == "Med Pens" }
      assert_equal 40.0, med_pens["netQuantity"]
      assert_equal "Medical Bay", med_pens["inventory"]["name"]
    end
  end

  test "GET /fleets/:slug/inventory-stock returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/inventory-stock with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
