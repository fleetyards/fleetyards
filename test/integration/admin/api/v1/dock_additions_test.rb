# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::DockAdditionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/dock-additions" do
    post("Create new DockAddition") do
      operationId "createDockAddition"
      tags "DockAdditions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::DockAdditionInput

      response(201, "successful") do
        schema ::Admin::V1::Schemas::DockAddition
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

    get("DockAdditions list") do
      operationId "dockAdditions"
      tags "DockAdditions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query,
        schema: {type: :string, default: DockAddition.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::DockAdditionQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::DockAdditions
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/dock-additions/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("DockAddition destroy") do
      operationId "destroyDockAddition"
      tags "DockAdditions"

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

    get("Get DockAddition") do
      operationId "dockAddition"
      tags "DockAdditions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::DockAddition
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

  test "POST /dock-additions names a ship the class does not cover" do
    dock = create(:dock)
    arrow = create(:model, name: "Arrow")
    sign_in @user

    assert_api_response :post, 201, body: {dockId: dock.id, modelId: arrow.id} do
      assert_equal [arrow.id], dock.added_models.map(&:id)
      assert_equal "Arrow", parsed_body["modelName"]
    end
  end

  test "POST /dock-additions returns 400 for a ship already named on that berth" do
    addition = create(:dock_addition)
    sign_in @user

    assert_api_response :post, 400,
      body: {dockId: addition.dock_id, modelId: addition.model_id}
  end

  test "POST /dock-additions returns 401 when not signed in" do
    dock = create(:dock)

    assert_api_response :post, 401, body: {dockId: dock.id, modelId: create(:model).id}
  end

  test "POST /dock-additions returns 403 for admin without access" do
    dock = create(:dock)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {dockId: dock.id, modelId: create(:model).id}
  end

  test "GET /dock-additions lists what a berth names" do
    create(:dock_addition)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /dock-additions filters by berth" do
    wanted = create(:dock_addition)
    create(:dock_addition)
    sign_in @user

    assert_api_response :get, 200, params: {q: {dockIdEq: wanted.dock_id}} do
      assert_equal [wanted.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /dock-additions returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /dock-additions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /dock-additions/:id returns the row" do
    addition = create(:dock_addition)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: addition.id}
  end

  test "GET /dock-additions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /dock-additions/:id returns 401 when not signed in" do
    addition = create(:dock_addition)

    assert_api_response :get, 401, path_params: {id: addition.id}
  end

  test "GET /dock-additions/:id returns 403 for admin without access" do
    addition = create(:dock_addition)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: addition.id}
  end

  test "DELETE /dock-additions/:id removes the name" do
    addition = create(:dock_addition)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: addition.id} do
      assert_not DockAddition.exists?(addition.id)
    end
  end

  test "DELETE /dock-additions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /dock-additions/:id returns 401 when not signed in" do
    addition = create(:dock_addition)

    assert_api_response :delete, 401, path_params: {id: addition.id}
  end

  test "DELETE /dock-additions/:id returns 403 for admin without access" do
    addition = create(:dock_addition)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: addition.id}
  end
end
