# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    delete("Clear Vehicle Inventory") do
      operationId "destroyVehicleInventory"
      tags "VehicleInventory"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "no content")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user)
  end

  test "DELETE /vehicles/:vehicle_id/inventory drops the inventory with its entries" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    create_list(:inventory_item, 2, inventory:)
    sign_in @user

    assert_difference "Inventory.count", -1 do
      assert_difference "InventoryItem.count", -2 do
        assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id}
      end
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory succeeds on a ship that never had one" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory leaves the ship alone" do
    create(:inventory, holder: @user, vehicle: @vehicle)
    sign_in @user

    assert_no_difference "Vehicle.count" do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory returns 404 for another user's ship" do
    create(:inventory, holder: @user, vehicle: @vehicle)
    sign_in @other_user

    assert_no_difference "Inventory.count" do
      assert_api_response :delete, 404, path_params: {vehicle_id: @vehicle.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "DELETE /vehicles/:vehicle_id/inventory with OAuth bearer token" do
    create(:inventory, holder: @user, vehicle: @vehicle)

    assert_difference "Inventory.count", -1 do
      assert_api_response :delete, 204,
        path_params: {vehicle_id: @vehicle.id},
        headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
    end
  end
end
