# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelHardpointsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/model-hardpoints" do
    post("Create Model Hardpoint") do
      operationId "createModelHardpoint"
      tags "ModelHardpoints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelHardpointInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoint"
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

    get("Model Hardpoints list") do
      operationId "listModelHardpoints"
      tags "ModelHardpoints"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelHardpointQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoints"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-hardpoints/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Destroy Model Hardpoint") do
      operationId "destroyModelHardpoint"
      tags "ModelHardpoints"

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

    get("Get Model Hardpoint") do
      operationId "modelHardpoint"
      tags "ModelHardpoints"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoint"
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

    put("Update Model Hardpoint") do
      operationId "updateModelHardpoint"
      tags "ModelHardpoints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelHardpointInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoint"
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
    @user = create(:admin_user, resource_access: [:model_hardpoints])
  end

  def valid_body(model)
    {
      name: "Hardpoint 01",
      source: "ship_matrix",
      key: "hardpoint_01",
      hardpointType: "weapons",
      group: "weapon",
      modelId: model.id
    }
  end

  # POST /model-hardpoints
  test "POST /model-hardpoints creates a hardpoint" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: valid_body(model)
  end

  test "POST /model-hardpoints returns 400 for missing required fields" do
    sign_in @user

    assert_api_response :post, 400, body: {name: "Missing required fields"}
  end

  test "POST /model-hardpoints returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: valid_body(model)
  end

  test "POST /model-hardpoints returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: valid_body(model)
  end

  # GET /model-hardpoints
  test "GET /model-hardpoints lists hardpoints" do
    create_list(:hardpoint, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-hardpoints returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-hardpoints returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-hardpoints/:id
  test "DELETE /model-hardpoints/:id destroys the hardpoint" do
    hardpoint = create(:hardpoint)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: hardpoint.id}
  end

  test "DELETE /model-hardpoints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-hardpoints/:id returns 401 when not signed in" do
    hardpoint = create(:hardpoint)

    assert_api_response :delete, 401, path_params: {id: hardpoint.id}
  end

  test "DELETE /model-hardpoints/:id returns 403 for admin without access" do
    hardpoint = create(:hardpoint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: hardpoint.id}
  end

  # GET /model-hardpoints/:id
  test "GET /model-hardpoints/:id returns the hardpoint" do
    hardpoint = create(:hardpoint)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: hardpoint.id}
  end

  test "GET /model-hardpoints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-hardpoints/:id returns 401 when not signed in" do
    hardpoint = create(:hardpoint)

    assert_api_response :get, 401, path_params: {id: hardpoint.id}
  end

  test "GET /model-hardpoints/:id returns 403 for admin without access" do
    hardpoint = create(:hardpoint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: hardpoint.id}
  end

  # PUT /model-hardpoints/:id
  test "PUT /model-hardpoints/:id updates the hardpoint" do
    hardpoint = create(:hardpoint)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: hardpoint.id}, body: {name: "Updated"}
  end

  test "PUT /model-hardpoints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {name: "x"}
  end

  test "PUT /model-hardpoints/:id returns 401 when not signed in" do
    hardpoint = create(:hardpoint)

    assert_api_response :put, 401, path_params: {id: hardpoint.id}, body: {name: "x"}
  end

  test "PUT /model-hardpoints/:id returns 403 for admin without access" do
    hardpoint = create(:hardpoint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: hardpoint.id}, body: {name: "x"}
  end
end
