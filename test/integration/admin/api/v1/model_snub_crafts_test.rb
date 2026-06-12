# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelSnubCraftsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update) so schema output
  # stays byte-identical to pre-migration.

  api_path "/model-snub-crafts" do
    post("Create Model Snub Craft") do
      operationId "createModelSnubCraft"
      tags "ModelSnubCrafts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelSnubCraftInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCraft"
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

    get("Model Snub Crafts list") do
      operationId "listModelSnubCrafts"
      tags "ModelSnubCrafts"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelSnubCraftQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCrafts"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-snub-crafts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Destroy Model Snub Craft") do
      operationId "destroyModelSnubCraft"
      tags "ModelSnubCrafts"

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

    get("Get Model Snub Craft") do
      operationId "modelSnubCraft"
      tags "ModelSnubCrafts"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCraft"
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

    put("Update Model Snub Craft") do
      operationId "updateModelSnubCraft"
      tags "ModelSnubCrafts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelSnubCraftInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCraft"
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
    @user = create(:admin_user, resource_access: [:model_snub_crafts])
  end

  # GET /model-snub-crafts
  test "GET /model-snub-crafts lists model snub crafts" do
    create_list(:model_snub_craft, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-snub-crafts returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-snub-crafts returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # POST /model-snub-crafts
  test "POST /model-snub-crafts creates a model snub craft" do
    model = create(:model)
    snub = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {modelId: model.id, snubCraftId: snub.id}
  end

  test "POST /model-snub-crafts returns 400 for invalid input" do
    sign_in @user

    assert_api_response :post, 400, body: {modelId: "00000000-0000-0000-0000-000000000000"}
  end

  test "POST /model-snub-crafts returns 401 when not signed in" do
    model = create(:model)
    snub = create(:model)

    assert_api_response :post, 401, body: {modelId: model.id, snubCraftId: snub.id}
  end

  test "POST /model-snub-crafts returns 403 for admin without access" do
    model = create(:model)
    snub = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {modelId: model.id, snubCraftId: snub.id}
  end

  # GET /model-snub-crafts/{id}
  test "GET /model-snub-crafts/:id returns the record" do
    record = create(:model_snub_craft)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: record.id}
  end

  test "GET /model-snub-crafts/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-snub-crafts/:id returns 401 when not signed in" do
    record = create(:model_snub_craft)

    assert_api_response :get, 401, path_params: {id: record.id}
  end

  test "GET /model-snub-crafts/:id returns 403 for admin without access" do
    record = create(:model_snub_craft)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: record.id}
  end

  # PUT /model-snub-crafts/{id}
  test "PUT /model-snub-crafts/:id updates the record" do
    record = create(:model_snub_craft)
    new_snub = create(:model)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: record.id}, body: {snubCraftId: new_snub.id}
  end

  test "PUT /model-snub-crafts/:id returns 404 for missing id" do
    new_snub = create(:model)
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {snubCraftId: new_snub.id}
  end

  test "PUT /model-snub-crafts/:id returns 401 when not signed in" do
    record = create(:model_snub_craft)
    new_snub = create(:model)

    assert_api_response :put, 401, path_params: {id: record.id}, body: {snubCraftId: new_snub.id}
  end

  test "PUT /model-snub-crafts/:id returns 403 for admin without access" do
    record = create(:model_snub_craft)
    new_snub = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: record.id}, body: {snubCraftId: new_snub.id}
  end

  # DELETE /model-snub-crafts/{id}
  test "DELETE /model-snub-crafts/:id destroys the record" do
    record = create(:model_snub_craft)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: record.id}
  end

  test "DELETE /model-snub-crafts/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-snub-crafts/:id returns 401 when not signed in" do
    record = create(:model_snub_craft)

    assert_api_response :delete, 401, path_params: {id: record.id}
  end

  test "DELETE /model-snub-crafts/:id returns 403 for admin without access" do
    record = create(:model_snub_craft)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: record.id}
  end
end
