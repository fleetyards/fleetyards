# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelPositionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/model-positions" do
    post("Create new Model Position") do
      operationId "createModelPosition"
      tags "ModelPositions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPositionInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"
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

    get("Model Positions list") do
      operationId "listModelPositions"
      tags "ModelPositions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPosition.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPositionQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPositions"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-positions/regenerate" do
    put("Regenerate Model Positions") do
      operationId "regenerateModelPositions"
      tags "ModelPositions"
      consumes "application/json"
      produces "application/json"

      parameter name: :model_id, in: :query, schema: {type: :string, format: :uuid}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPositions"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-positions/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Model Position destroy") do
      operationId "destroyModelPosition"
      tags "ModelPositions"

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

    get("Get Model Position") do
      operationId "modelPosition"
      tags "ModelPositions"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"
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

    put("Update Model Position") do
      operationId "updateModelPosition"
      tags "ModelPositions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPositionInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"
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
    @user = create(:admin_user, resource_access: [:model_positions])
  end

  # POST /model-positions
  test "POST /model-positions creates a position" do
    model = create(:model)
    sign_in @user

    body = {modelId: model.id, name: "Passenger 1", positionType: "passenger", source: "curated", position: 5}
    assert_api_response :post, 201, body: body
  end

  test "POST /model-positions returns 400 for invalid body" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 400, body: {modelId: model.id}
  end

  test "POST /model-positions returns 401 when not signed in" do
    model = create(:model)

    body = {modelId: model.id, name: "x", positionType: "passenger", source: "curated", position: 5}
    assert_api_response :post, 401, body: body
  end

  test "POST /model-positions returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    body = {modelId: model.id, name: "x", positionType: "passenger", source: "curated", position: 5}
    assert_api_response :post, 403, body: body
  end

  # GET /model-positions
  test "GET /model-positions lists positions" do
    create_list(:model_position, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-positions returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-positions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # PUT /model-positions/regenerate
  test "PUT /model-positions/regenerate regenerates positions for a model" do
    model = create(:model)
    create(:model_position, model: model)
    sign_in @user

    assert_api_response :put, 200, params: {model_id: model.id}, body: {}
  end

  test "PUT /model-positions/regenerate returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :put, 401, params: {model_id: model.id}, body: {}
  end

  test "PUT /model-positions/regenerate returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, params: {model_id: model.id}, body: {}
  end

  # DELETE /model-positions/:id
  test "DELETE /model-positions/:id destroys the position" do
    position = create(:model_position)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: position.id}
  end

  test "DELETE /model-positions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-positions/:id returns 401 when not signed in" do
    position = create(:model_position)

    assert_api_response :delete, 401, path_params: {id: position.id}
  end

  test "DELETE /model-positions/:id returns 403 for admin without access" do
    position = create(:model_position)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: position.id}
  end

  # GET /model-positions/:id
  test "GET /model-positions/:id returns the position" do
    position = create(:model_position)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: position.id}
  end

  test "GET /model-positions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-positions/:id returns 401 when not signed in" do
    position = create(:model_position)

    assert_api_response :get, 401, path_params: {id: position.id}
  end

  test "GET /model-positions/:id returns 403 for admin without access" do
    position = create(:model_position)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: position.id}
  end

  # PUT /model-positions/:id
  test "PUT /model-positions/:id updates the position" do
    position = create(:model_position)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: position.id}, body: {name: "Updated Position"}
  end

  test "PUT /model-positions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {name: "x"}
  end

  test "PUT /model-positions/:id returns 401 when not signed in" do
    position = create(:model_position)

    assert_api_response :put, 401, path_params: {id: position.id}, body: {name: "x"}
  end

  test "PUT /model-positions/:id returns 403 for admin without access" do
    position = create(:model_position)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: position.id}, body: {name: "x"}
  end
end
