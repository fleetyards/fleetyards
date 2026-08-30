# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetInventoryItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/inventories/{fleet_inventory_id}/items" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "fleet_inventory_id", in: :path, description: "Fleet inventory id", schema: {type: :string, format: :uuid}

    get("Fleet Inventory Items list") do
      operationId "fleetInventoryItems"
      tags "FleetInventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetInventoryItems
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/fleets/{fleet_id}/inventories/{fleet_inventory_id}/items/{id}" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "fleet_inventory_id", in: :path, description: "Fleet inventory id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet inventory item id", schema: {type: :string, format: :uuid}

    get("One fleet inventory item") do
      operationId "fleetInventoryItem"
      tags "FleetInventories"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetInventoryItem
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:fleets])
    @fleet = create(:fleet, created_by: create(:user).id)
    @inventory = create(:fleet_inventory, fleet: @fleet)
    @item = create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Titanium")
  end

  def index_path = "/fleets/{fleet_id}/inventories/{fleet_inventory_id}/items"

  def show_path = "/fleets/{fleet_id}/inventories/{fleet_inventory_id}/items/{id}"

  def index_params = {fleet_id: @fleet.id, fleet_inventory_id: @inventory.id}

  test "GET .../items lists the entries in the inventory" do
    create(:fleet_inventory_item, fleet_inventory: create(:fleet_inventory, fleet: @fleet), name: "Elsewhere")
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: index_params do
      assert_equal ["Titanium"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # `quantity` is a decimal, and a json number would round it. It travels as a
  # string for the same reason prices do.
  test "GET .../items sends the quantity as a string" do
    @item.update!(quantity: 12.5)
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: index_params do
      assert_equal "12.5", parsed_body["items"].first["quantity"]
    end
  end

  test "GET .../items returns 404 for a missing inventory" do
    sign_in @admin

    assert_api_response :get, 404, api_path: index_path,
      path_params: {fleet_id: @fleet.id, fleet_inventory_id: SecureRandom.uuid}
  end

  test "GET .../items returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: index_path, path_params: index_params
  end

  test "GET .../items returns 403 for an admin without fleet access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: index_path, path_params: index_params
  end

  test "GET .../items/:id returns the entry" do
    sign_in @admin

    assert_api_response :get, 200, api_path: show_path, path_params: index_params.merge(id: @item.id) do
      assert_equal "Titanium", parsed_body["name"]
      assert_equal @inventory.id, parsed_body["fleetInventoryId"]
    end
  end

  test "GET .../items/:id returns 404 for an entry in another inventory" do
    other = create(:fleet_inventory_item, fleet_inventory: create(:fleet_inventory, fleet: @fleet))
    sign_in @admin

    assert_api_response :get, 404, api_path: show_path, path_params: index_params.merge(id: other.id)
  end

  test "GET .../items/:id returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: show_path, path_params: index_params.merge(id: @item.id)
  end

  test "GET .../items/:id returns 403 for an admin without fleet access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: show_path, path_params: index_params.merge(id: @item.id)
  end
end
