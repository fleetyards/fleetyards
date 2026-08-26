# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryItemsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/items" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("Vehicle Inventory Items List") do
      operationId "vehicleInventoryItems"
      tags "VehicleInventoryItems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: InventoryItem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/InventoryItemQuery"},
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/InventoryItemsList"
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

  test "GET /vehicles/:vehicle_id/inventory/items lists the ledger entries" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    create_list(:inventory_item, 3, inventory:)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/items is empty for an untouched ship" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
        assert_empty parsed_body["items"]
      end
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/items keeps other ships out" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    create(:inventory_item, inventory:, name: "Quantanium")

    other_ship = create(:vehicle, user: @user)
    create(:inventory_item, inventory: create(:inventory, holder: @user, vehicle: other_ship), name: "Titanium")

    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal ["Quantanium"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/items filters by name" do
    inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    create(:inventory_item, inventory:, name: "Quantanium")
    create(:inventory_item, inventory:, name: "Titanium")
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id}, params: {q: {nameCont: "Quant"}} do
      assert_equal ["Quantanium"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /vehicles/:vehicle_id/inventory/items returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory/items returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/inventory/items with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
