# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/stock" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("Vehicle Inventory Stock") do
      operationId "vehicleInventoryStock"
      tags "VehicleInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/InventoryStockPosition"}
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
  end

  test "GET /vehicles/:vehicle_id/inventory/stock nets what is aboard" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    create(:inventory_item, inventory:, name: "Quantanium", quantity: 100, unit: :scu)
    create(:inventory_item, :withdrawal, inventory:, name: "Quantanium", quantity: 30, unit: :scu)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal 1, parsed_body.count
      assert_equal "Quantanium", parsed_body.first["name"]
      assert_in_delta 70.0, parsed_body.first["netQuantity"]
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/stock is empty for an untouched ship" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
        assert_empty parsed_body
      end
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/stock returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory/stock with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
