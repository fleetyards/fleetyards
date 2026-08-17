# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryStockShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/stock/{slug}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    get("Vehicle Inventory Stock Position") do
      operationId "vehicleInventoryStockItem"
      tags "VehicleInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/InventoryStockPosition"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("ship_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user)
    @inventory = create(:inventory, holder: @user, vehicle: @vehicle)

    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu, quality: 900)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 20, unit: :scu, quality: 500)
    create(:inventory_item, :withdrawal, inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu)

    @slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug rolls up the position" do
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, slug: @slug} do
      assert_equal "Quantanium", parsed_body["name"]
      assert_in_delta 90.0, parsed_body["netQuantity"]
      assert_equal 3, parsed_body["entriesCount"]
      assert_equal @inventory.slug, parsed_body["inventory"]["slug"]
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug returns 404 for an unknown position" do
    sign_in @user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id, slug: "nope--commodity--scu"}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug returns 404 on an untouched ship" do
    untouched = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :get, 404, path_params: {vehicle_id: untouched.id, slug: @slug}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id, slug: @slug}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id, slug: @slug}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id, slug: @slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
