# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryItemsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/items" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    post("Create Vehicle Inventory Item") do
      operationId "createVehicleInventoryItem"
      tags "VehicleInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::InventoryItemCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Hangar::Logistics::InventoryItem
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
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
    Flipper.enable("ship_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user, model: create(:model, name: "Ironclad"))
  end

  def item_body(overrides = {})
    {name: "Quantanium", category: "commodity", quantity: 250.5, unit: "scu", entryType: "deposit"}.merge(overrides)
  end

  test "POST /vehicles/:vehicle_id/inventory/items provisions the inventory on the first deposit" do
    sign_in @user

    assert_difference "Inventory.count", 1 do
      assert_api_response :post, 201, path_params: {vehicle_id: @vehicle.id}, body: item_body do
        assert_equal "Quantanium", parsed_body["name"]
        assert_in_delta 250.5, parsed_body["quantity"]
        assert_equal "Ironclad Inventory", parsed_body["inventory"]["name"]
      end
    end

    assert_equal @vehicle, Inventory.last.vehicle
  end

  test "POST /vehicles/:vehicle_id/inventory/items reuses the inventory on later deposits" do
    sign_in @user

    assert_api_response :post, 201, path_params: {vehicle_id: @vehicle.id}, body: item_body

    assert_no_difference "Inventory.count" do
      assert_api_response :post, 201,
        path_params: {vehicle_id: @vehicle.id},
        body: item_body(name: "Titanium")
    end

    assert_equal 2, @vehicle.inventory.inventory_items.count
  end

  test "POST /vehicles/:vehicle_id/inventory/items leaves no inventory behind when the entry is rejected" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :post, 400, path_params: {vehicle_id: @vehicle.id}, body: item_body(quantity: 0)
    end
  end

  test "POST /vehicles/:vehicle_id/inventory/items rejects a withdrawal that exceeds the stock" do
    sign_in @user

    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      body: item_body(quantity: 10)

    assert_api_response :post, 400,
      path_params: {vehicle_id: @vehicle.id},
      body: item_body(quantity: 20, entryType: "withdrawal")
  end

  test "POST /vehicles/:vehicle_id/inventory/items returns 404 for another user's ship" do
    sign_in @other_user

    assert_no_difference "Inventory.count" do
      assert_api_response :post, 404, path_params: {vehicle_id: @vehicle.id}, body: item_body
    end
  end

  test "POST /vehicles/:vehicle_id/inventory/items returns 401 when not signed in" do
    assert_no_difference "Inventory.count" do
      assert_api_response :post, 401, path_params: {vehicle_id: @vehicle.id}, body: item_body
    end
  end

  test "POST /vehicles/:vehicle_id/inventory/items with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: item_body
  end
end
