# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelLoanersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/model-loaners" do
    post("Create Model Loaner") do
      operationId "createModelLoaner"
      tags "ModelLoaners"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"
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

    get("Model Loaners list") do
      operationId "listModelLoaners"
      tags "ModelLoaners"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelLoanerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaners"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-loaners/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Destroy Model Loaner") do
      operationId "destroyModelLoaner"
      tags "ModelLoaners"

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

    get("Get Model Loaner") do
      operationId "modelLoaner"
      tags "ModelLoaners"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"
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

    put("Update Model Loaner") do
      operationId "updateModelLoaner"
      tags "ModelLoaners"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelLoanerInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelLoaner"
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
    @user = create(:admin_user, resource_access: [:model_loaners])
  end

  # POST /model-loaners
  test "POST /model-loaners creates a loaner mapping" do
    model = create(:model)
    loaner = create(:model)
    sign_in @user

    assert_api_response :post, 201, body: {modelId: model.id, loanerModelId: loaner.id}
  end

  test "POST /model-loaners returns 400 for unknown model" do
    sign_in @user

    assert_api_response :post, 400, body: {modelId: "00000000-0000-0000-0000-000000000000"}
  end

  test "POST /model-loaners returns 401 when not signed in" do
    model = create(:model)
    loaner = create(:model)

    assert_api_response :post, 401, body: {modelId: model.id, loanerModelId: loaner.id}
  end

  test "POST /model-loaners returns 403 for admin without access" do
    model = create(:model)
    loaner = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {modelId: model.id, loanerModelId: loaner.id}
  end

  # GET /model-loaners
  test "GET /model-loaners lists loaner mappings" do
    create_list(:model_loaner, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-loaners returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-loaners returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-loaners/:id
  test "DELETE /model-loaners/:id destroys the mapping" do
    loaner = create(:model_loaner)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: loaner.id}
  end

  test "DELETE /model-loaners/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /model-loaners/:id returns 401 when not signed in" do
    loaner = create(:model_loaner)

    assert_api_response :delete, 401, path_params: {id: loaner.id}
  end

  test "DELETE /model-loaners/:id returns 403 for admin without access" do
    loaner = create(:model_loaner)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: loaner.id}
  end

  # GET /model-loaners/:id
  test "GET /model-loaners/:id returns the mapping" do
    loaner = create(:model_loaner)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: loaner.id}
  end

  test "GET /model-loaners/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /model-loaners/:id returns 401 when not signed in" do
    loaner = create(:model_loaner)

    assert_api_response :get, 401, path_params: {id: loaner.id}
  end

  test "GET /model-loaners/:id returns 403 for admin without access" do
    loaner = create(:model_loaner)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: loaner.id}
  end

  # PUT /model-loaners/:id
  test "PUT /model-loaners/:id updates the mapping" do
    loaner = create(:model_loaner)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: loaner.id}, body: {hidden: true}
  end

  test "PUT /model-loaners/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {hidden: true}
  end

  test "PUT /model-loaners/:id returns 401 when not signed in" do
    loaner = create(:model_loaner)

    assert_api_response :put, 401, path_params: {id: loaner.id}, body: {hidden: true}
  end

  test "PUT /model-loaners/:id returns 403 for admin without access" do
    loaner = create(:model_loaner)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: loaner.id}, body: {hidden: true}
  end
end
