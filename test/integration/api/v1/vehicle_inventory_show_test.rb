# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("Vehicle Inventory") do
      operationId "vehicleInventory"
      tags "VehicleInventory"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Inventory"
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
    @model = create(:model, name: "Ironclad", cargo: 400)
    @vehicle = create(:vehicle, :with_serial, user: @user, model: @model)
  end

  test "GET /vehicles/:vehicle_id/inventory describes the inventory the ship would have" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
        assert_nil parsed_body["id"]
        assert_equal "Ironclad Inventory", parsed_body["name"]
        assert_equal 0, parsed_body["itemCount"]
        assert_in_delta 0.0, parsed_body["totalScu"]
        assert_equal @vehicle.id, parsed_body["vehicle"]["id"]
        assert_in_delta 400.0, parsed_body["vehicle"]["model"]["cargo"]
      end
    end
  end

  test "GET /vehicles/:vehicle_id/inventory reports what is aboard" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle, name: "Ironclad Inventory")
    create(:inventory_item, inventory:, name: "Quantanium", quantity: 312, unit: :scu)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal inventory.id, parsed_body["id"]
      assert_equal 1, parsed_body["itemCount"]
      assert_in_delta 312.0, parsed_body["totalScu"]
    end
  end

  test "GET /vehicles/:vehicle_id/inventory addresses the ship by serial" do
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.serial} do
      assert_equal "Ironclad Inventory", parsed_body["name"]
    end
  end

  test "GET /vehicles/:vehicle_id/inventory names an unnamed ship after its model" do
    named = create(:vehicle, user: @user, model: @model, name: "Rustbucket")
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: named.id} do
      assert_equal "Rustbucket Inventory", parsed_body["name"]
    end
  end

  test "GET /vehicles/:vehicle_id/inventory returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
