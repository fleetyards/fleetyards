# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::DockCapacitiesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/dock-capacities" do
    post("Create new DockCapacity") do
      operationId "createDockCapacity"
      tags "DockCapacities"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::DockCapacityInput

      response(201, "successful") do
        schema ::Admin::V1::Schemas::DockCapacity
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("DockCapacities list") do
      operationId "dockCapacities"
      tags "DockCapacities"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query,
        schema: {type: :string, default: DockCapacity.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::DockCapacityQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::DockCapacities
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/dock-capacities/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("DockCapacity destroy") do
      operationId "destroyDockCapacity"
      tags "DockCapacities"

      response(204, "successful")

      response(404, "not_found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Get DockCapacity") do
      operationId "dockCapacity"
      tags "DockCapacities"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::DockCapacity
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

    put("Update DockCapacity") do
      operationId "updateDockCapacity"
      tags "DockCapacities"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::DockCapacityInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::DockCapacity
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
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
    @user = create(:admin_user, resource_access: [:docks])
  end

  test "POST /dock-capacities records what a berth is built for" do
    dock = create(:dock, dock_type: :hangar)
    sign_in @user

    body = {dockId: dock.id, ladder: "ship", size: "small", quantity: 3, display: true}
    assert_api_response :post, 201, body: body do
      assert_equal 3, dock.capacities.sole.quantity
    end
  end

  # The Ironclad's deck: six Ursas or two Novas, on the curated vehicle ladder.
  test "POST /dock-capacities takes an entry on the vehicle ladder" do
    dock = create(:dock, dock_type: :cargogrid)
    sign_in @user

    body = {dockId: dock.id, ladder: "vehicle", size: "large", quantity: 6}
    assert_api_response :post, 201, body: body
  end

  test "POST /dock-capacities returns 400 for a class off its ladder" do
    dock = create(:dock)
    sign_in @user

    body = {dockId: dock.id, ladder: "ship", size: "extra_extra_large", quantity: 1}
    assert_api_response :post, 400, body: body
  end

  test "POST /dock-capacities returns 400 for a second display entry" do
    dock = create(:dock)
    create(:dock_capacity, dock:, ladder: :ship, size: "small", display: true)
    sign_in @user

    body = {dockId: dock.id, ladder: "ship", size: "medium", quantity: 2, display: true}
    assert_api_response :post, 400, body: body
  end

  test "POST /dock-capacities returns 401 when not signed in" do
    dock = create(:dock)

    assert_api_response :post, 401, body: {dockId: dock.id, ladder: "ship", size: "small"}
  end

  test "POST /dock-capacities returns 403 for admin without access" do
    dock = create(:dock)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {dockId: dock.id, ladder: "ship", size: "small"}
  end

  test "GET /dock-capacities lists entries" do
    create(:dock_capacity)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /dock-capacities filters by dock" do
    wanted = create(:dock_capacity, size: "small")
    create(:dock_capacity, size: "medium")
    sign_in @user

    assert_api_response :get, 200, params: {q: {dockIdEq: wanted.dock_id}} do
      assert_equal [wanted.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /dock-capacities returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /dock-capacities returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /dock-capacities/:id returns the entry" do
    entry = create(:dock_capacity)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: entry.id}
  end

  test "GET /dock-capacities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /dock-capacities/:id returns 401 when not signed in" do
    entry = create(:dock_capacity)

    assert_api_response :get, 401, path_params: {id: entry.id}
  end

  test "GET /dock-capacities/:id returns 403 for admin without access" do
    entry = create(:dock_capacity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: entry.id}
  end

  test "PUT /dock-capacities/:id updates the entry" do
    entry = create(:dock_capacity, quantity: 1)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: entry.id}, body: {quantity: 4} do
      assert_equal 4, entry.reload.quantity
    end
  end

  test "PUT /dock-capacities/:id returns 400 for a quantity below one" do
    entry = create(:dock_capacity)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: entry.id}, body: {quantity: 0}
  end

  test "PUT /dock-capacities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {quantity: 2}
  end

  test "PUT /dock-capacities/:id returns 401 when not signed in" do
    entry = create(:dock_capacity)

    assert_api_response :put, 401, path_params: {id: entry.id}, body: {quantity: 2}
  end

  test "PUT /dock-capacities/:id returns 403 for admin without access" do
    entry = create(:dock_capacity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: entry.id}, body: {quantity: 2}
  end

  test "DELETE /dock-capacities/:id destroys the entry" do
    entry = create(:dock_capacity)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: entry.id} do
      assert_not DockCapacity.exists?(entry.id)
    end
  end

  test "DELETE /dock-capacities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /dock-capacities/:id returns 401 when not signed in" do
    entry = create(:dock_capacity)

    assert_api_response :delete, 401, path_params: {id: entry.id}
  end

  test "DELETE /dock-capacities/:id returns 403 for admin without access" do
    entry = create(:dock_capacity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: entry.id}
  end
end
