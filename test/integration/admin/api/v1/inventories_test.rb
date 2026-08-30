# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::InventoriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/users/{user_id}/inventories" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    get("User Inventories list") do
      operationId "userInventories"
      tags "Inventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Inventories
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

  api_path "/users/{user_id}/inventories/{id}" do
    parameter name: "user_id", in: :path, description: "User id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Inventory id", schema: {type: :string, format: :uuid}

    get("One user inventory") do
      operationId "userInventory"
      tags "Inventories"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Inventory
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
    @inventory = create(:inventory, holder: @holder, name: "Locker")
  end

  def index_path = "/users/{user_id}/inventories"

  def show_path = "/users/{user_id}/inventories/{id}"

  test "GET /users/:user_id/inventories lists what the user holds" do
    create(:inventory, holder: create(:user), name: "Someone Else's")
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: {user_id: @holder.id} do
      assert_equal ["Locker"], parsed_body["items"].map { |item| item["name"] }
      assert_equal "User", parsed_body["items"].first["holderType"]
    end
  end

  test "GET /users/:user_id/inventories counts the entries in one" do
    create_list(:inventory_item, 3, inventory: @inventory)
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: {user_id: @holder.id} do
      assert_equal 3, parsed_body["items"].first["itemsCount"]
    end
  end

  test "GET /users/:user_id/inventories returns 404 for a missing user" do
    sign_in @admin

    assert_api_response :get, 404, api_path: index_path, path_params: {user_id: SecureRandom.uuid}
  end

  test "GET /users/:user_id/inventories returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: index_path, path_params: {user_id: @holder.id}
  end

  test "GET /users/:user_id/inventories returns 403 for an admin without user access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: index_path, path_params: {user_id: @holder.id}
  end

  test "GET /users/:user_id/inventories/:id returns the inventory" do
    sign_in @admin

    assert_api_response :get, 200, api_path: show_path, path_params: {user_id: @holder.id, id: @inventory.id} do
      assert_equal "Locker", parsed_body["name"]
      assert_nil parsed_body["vehicleId"]
    end
  end

  test "GET /users/:user_id/inventories/:id returns 404 for another user's inventory" do
    other = create(:inventory, holder: create(:user))
    sign_in @admin

    assert_api_response :get, 404, api_path: show_path, path_params: {user_id: @holder.id, id: other.id}
  end

  test "GET /users/:user_id/inventories/:id returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: show_path, path_params: {user_id: @holder.id, id: @inventory.id}
  end

  test "GET /users/:user_id/inventories/:id returns 403 for an admin without user access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: show_path, path_params: {user_id: @holder.id, id: @inventory.id}
  end
end
