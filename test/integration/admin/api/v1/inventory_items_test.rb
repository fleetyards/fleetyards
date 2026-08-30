# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::InventoryItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{user_id}/inventories/{inventory_id}/items" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}
    parameter name: "inventory_id", in: :path, description: "Inventory id", schema: {type: :string, format: :uuid}

    get("Inventory Items list") do
      operationId "userInventoryItems"
      tags "Inventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::InventoryItems
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

  api_path "/users/{user_id}/inventories/{inventory_id}/items/{id}" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}
    parameter name: "inventory_id", in: :path, description: "Inventory id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Inventory item id", schema: {type: :string, format: :uuid}

    get("One inventory item") do
      operationId "userInventoryItem"
      tags "Inventories"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::InventoryItem
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
    @admin = create(:admin_user, resource_access: [:users])
    @holder = create(:user)
    @inventory = create(:inventory, holder: @holder)
    @item = create(:inventory_item, inventory: @inventory, name: "Medpen")
  end

  def index_path = "/users/{user_id}/inventories/{inventory_id}/items"

  def show_path = "/users/{user_id}/inventories/{inventory_id}/items/{id}"

  def index_params = {user_id: @holder.id, inventory_id: @inventory.id}

  test "GET .../items lists the entries in the inventory" do
    create(:inventory_item, inventory: create(:inventory, holder: @holder), name: "Elsewhere")
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: index_params do
      assert_equal ["Medpen"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET .../items sends the quantity as a string" do
    @item.update!(quantity: 7.25)
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: index_params do
      assert_equal "7.25", parsed_body["items"].first["quantity"]
    end
  end

  test "GET .../items returns 404 for a missing inventory" do
    sign_in @admin

    assert_api_response :get, 404, api_path: index_path,
      path_params: {user_id: @holder.id, inventory_id: SecureRandom.uuid}
  end

  test "GET .../items returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: index_path, path_params: index_params
  end

  test "GET .../items returns 403 for an admin without user access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: index_path, path_params: index_params
  end

  test "GET .../items/:id returns the entry" do
    sign_in @admin

    assert_api_response :get, 200, api_path: show_path, path_params: index_params.merge(id: @item.id) do
      assert_equal "Medpen", parsed_body["name"]
      assert_equal @inventory.id, parsed_body["inventoryId"]
    end
  end

  test "GET .../items/:id returns 404 for an entry in another inventory" do
    other = create(:inventory_item, inventory: create(:inventory, holder: @holder))
    sign_in @admin

    assert_api_response :get, 404, api_path: show_path, path_params: index_params.merge(id: other.id)
  end

  test "GET .../items/:id returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: show_path, path_params: index_params.merge(id: @item.id)
  end

  test "GET .../items/:id returns 403 for an admin without user access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: show_path, path_params: index_params.merge(id: @item.id)
  end
end
