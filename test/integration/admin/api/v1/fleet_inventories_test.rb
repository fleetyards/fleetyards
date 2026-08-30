# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetInventoriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{fleet_id}/inventories" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    get("Fleet Inventories list") do
      operationId "fleetInventories"
      tags "FleetInventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetInventories
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

  api_path "/fleets/{fleet_id}/inventories/{id}" do
    parameter name: "fleet_id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Fleet inventory id", schema: {type: :string, format: :uuid}

    get("One fleet inventory") do
      operationId "fleetInventory"
      tags "FleetInventories"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FleetInventory
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
    @inventory = create(:fleet_inventory, fleet: @fleet, name: "Quartermaster's Hold")
  end

  def index_path = "/fleets/{fleet_id}/inventories"

  def show_path = "/fleets/{fleet_id}/inventories/{id}"

  test "GET /fleets/:fleet_id/inventories lists the fleet's inventories" do
    create(:fleet_inventory, fleet: create(:fleet, created_by: create(:user).id), name: "Another Fleet's")
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: {fleet_id: @fleet.id} do
      assert_equal ["Quartermaster's Hold"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /fleets/:fleet_id/inventories counts the entries in one" do
    create_list(:fleet_inventory_item, 2, fleet_inventory: @inventory)
    sign_in @admin

    assert_api_response :get, 200, api_path: index_path, path_params: {fleet_id: @fleet.id} do
      assert_equal 2, parsed_body["items"].first["itemsCount"]
    end
  end

  test "GET /fleets/:fleet_id/inventories returns 404 for a missing fleet" do
    sign_in @admin

    assert_api_response :get, 404, api_path: index_path, path_params: {fleet_id: SecureRandom.uuid}
  end

  test "GET /fleets/:fleet_id/inventories returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: index_path, path_params: {fleet_id: @fleet.id}
  end

  test "GET /fleets/:fleet_id/inventories returns 403 for an admin without fleet access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: index_path, path_params: {fleet_id: @fleet.id}
  end

  test "GET /fleets/:fleet_id/inventories/:id returns the inventory" do
    sign_in @admin

    assert_api_response :get, 200, api_path: show_path, path_params: {fleet_id: @fleet.id, id: @inventory.id} do
      assert_equal "Quartermaster's Hold", parsed_body["name"]
      assert_equal "members_only", parsed_body["visibility"]
    end
  end

  test "GET /fleets/:fleet_id/inventories/:id names the manager when one is set" do
    manager = create(:user)
    @inventory.update!(manager:)
    sign_in @admin

    assert_api_response :get, 200, api_path: show_path, path_params: {fleet_id: @fleet.id, id: @inventory.id} do
      assert_equal manager.username, parsed_body["managerUsername"]
    end
  end

  # The fleet in the path is what scopes the lookup, so another fleet's
  # inventory is not readable through a fleet the admin may see.
  test "GET /fleets/:fleet_id/inventories/:id returns 404 for another fleet's inventory" do
    other = create(:fleet_inventory, fleet: create(:fleet, created_by: create(:user).id))
    sign_in @admin

    assert_api_response :get, 404, api_path: show_path, path_params: {fleet_id: @fleet.id, id: other.id}
  end

  test "GET /fleets/:fleet_id/inventories/:id returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: show_path, path_params: {fleet_id: @fleet.id, id: @inventory.id}
  end

  test "GET /fleets/:fleet_id/inventories/:id returns 403 for an admin without fleet access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: show_path, path_params: {fleet_id: @fleet.id, id: @inventory.id}
  end
end
