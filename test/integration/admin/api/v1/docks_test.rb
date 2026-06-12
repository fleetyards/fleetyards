# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::DocksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/docks" do
    post("Create new Dock") do
      operationId "createDock"
      tags "Docks"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/DockInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Dock"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Docks list") do
      operationId "docks"
      tags "Docks"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Dock.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/DockQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Docks"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/docks/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Dock destroy") do
      operationId "destroyDock"
      tags "Docks"

      response(204, "successful")

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Get Dock") do
      operationId "dock"
      tags "Docks"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Dock"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Dock") do
      operationId "updateDock"
      tags "Docks"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/DockInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Dock"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:docks])
  end

  # POST /docks
  test "POST /docks creates a dock" do
    model = create(:model)
    sign_in @user

    body = {name: "Pad 01", dockType: "landingpad", shipSize: "medium", modelId: model.id}
    assert_api_response :post, 201, body: body
  end

  test "POST /docks returns 400 for missing required fields" do
    sign_in @user

    assert_api_response :post, 400, body: {name: "Missing required fields"}
  end

  test "POST /docks returns 401 when not signed in" do
    model = create(:model)

    body = {name: "x", dockType: "landingpad", shipSize: "medium", modelId: model.id}
    assert_api_response :post, 401, body: body
  end

  test "POST /docks returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    body = {name: "x", dockType: "landingpad", shipSize: "medium", modelId: model.id}
    assert_api_response :post, 403, body: body
  end

  # GET /docks
  test "GET /docks lists docks" do
    create_list(:dock, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /docks returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /docks returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /docks/:id
  test "DELETE /docks/:id destroys the dock" do
    dock = create(:dock)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: dock.id}
  end

  test "DELETE /docks/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /docks/:id returns 401 when not signed in" do
    dock = create(:dock)

    assert_api_response :delete, 401, path_params: {id: dock.id}
  end

  test "DELETE /docks/:id returns 403 for admin without access" do
    dock = create(:dock)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: dock.id}
  end

  # GET /docks/:id
  test "GET /docks/:id returns the dock" do
    dock = create(:dock)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: dock.id}
  end

  test "GET /docks/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /docks/:id returns 401 when not signed in" do
    dock = create(:dock)

    assert_api_response :get, 401, path_params: {id: dock.id}
  end

  test "GET /docks/:id returns 403 for admin without access" do
    dock = create(:dock)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: dock.id}
  end

  # PUT /docks/:id
  test "PUT /docks/:id updates the dock" do
    dock = create(:dock)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: dock.id}, body: {name: "Updated Pad"}
  end

  test "PUT /docks/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {name: "x"}
  end

  test "PUT /docks/:id returns 401 when not signed in" do
    dock = create(:dock)

    assert_api_response :put, 401, path_params: {id: dock.id}, body: {name: "x"}
  end

  test "PUT /docks/:id returns 403 for admin without access" do
    dock = create(:dock)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: dock.id}, body: {name: "x"}
  end
end
