# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarAllInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventory-stock" do
    get("Hangar All Inventory Stock") do
      operationId "hangarAllInventoryStock"
      tags "HangarInventoryStock"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/InventoryStockQuery"},
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarInventoryStockItemsList"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    inv1 = create(:inventory, holder: @user, name: "Mining Ops")
    inv2 = create(:inventory, holder: @user, name: "Medical Bay")
    create(:inventory_item, inventory: inv1, name: "Quantanium", category: :commodity, quantity: 200, unit: :scu, entry_type: :deposit)
    create(:inventory_item, inventory: inv2, name: "Med Pens", category: :consumable, quantity: 50, unit: :units, entry_type: :deposit)
    create(:inventory_item, inventory: inv2, name: "Med Pens", category: :consumable, quantity: 10, unit: :units, entry_type: :withdrawal)
  end

  test "GET /hangar/inventory-stock aggregates across inventories" do
    sign_in @user

    assert_api_response :get, 200 do
      quantanium = parsed_body.find { |d| d["name"] == "Quantanium" }
      assert_equal 200.0, quantanium["netQuantity"]
      assert_equal "Mining Ops", quantanium["inventory"]["name"]

      med_pens = parsed_body.find { |d| d["name"] == "Med Pens" }
      assert_equal 40.0, med_pens["netQuantity"]
      assert_equal "Medical Bay", med_pens["inventory"]["name"]
    end
  end

  test "GET /hangar/inventory-stock does not include other users' stock" do
    other_inventory = create(:inventory, holder: @other_user, name: "Foreign Bay")
    create(:inventory_item, inventory: other_inventory, name: "Titanium", category: :commodity, quantity: 10, unit: :scu, entry_type: :deposit)
    sign_in @user

    assert_api_response :get, 200 do
      assert_nil parsed_body.find { |d| d["name"] == "Titanium" }
    end
  end

  test "GET /hangar/inventory-stock narrows to one ship" do
    Flipper.enable("ship_inventories")
    vehicle = create(:vehicle, user: @user)
    aboard = create(:inventory, holder: @user, vehicle:, name: "Ironclad Inventory")
    create(:inventory_item, inventory: aboard, name: "Titanium", category: :commodity, quantity: 15, unit: :scu)
    sign_in @user

    assert_api_response :get, 200, params: {q: {vehicleIdEq: vehicle.id}} do
      assert_equal ["Titanium"], parsed_body.map { |d| d["name"] }
    end
  end

  test "GET /hangar/inventory-stock ignores a ship that is not the user's" do
    Flipper.enable("ship_inventories")
    sign_in @user

    assert_api_response :get, 200, params: {q: {vehicleIdEq: create(:vehicle, user: @other_user).id}} do
      assert_empty parsed_body
    end
  end

  test "GET /hangar/inventory-stock leaves out what is aboard a ship while ship_inventories is off" do
    Flipper.disable("ship_inventories")
    vehicle = create(:vehicle, user: @user)
    aboard = create(:inventory, holder: @user, vehicle:, name: "Ironclad Inventory")
    create(:inventory_item, inventory: aboard, name: "Titanium", category: :commodity, quantity: 15, unit: :scu)
    sign_in @user

    assert_api_response :get, 200 do
      assert_nil parsed_body.find { |d| d["name"] == "Titanium" }
      assert_includes parsed_body.map { |d| d["name"] }, "Quantanium"
    end
  end

  test "GET /hangar/inventory-stock returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/inventory-stock with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
