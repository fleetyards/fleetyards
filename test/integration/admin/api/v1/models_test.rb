# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models" do
    post("Create Model") do
      operationId "createModel"
      tags "Models"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelCreateInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Models list") do
      operationId "models"
      tags "Models"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Models"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/models/{id}" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    delete("Destroy Model") do
      operationId "destroyModel"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
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

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
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

    put("Update Model") do
      operationId "updateModel"
      tags "Models"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelUpdateInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
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
    @user = create(:admin_user, resource_access: [:models])
  end

  # POST /models
  test "POST /models creates a model" do
    manufacturer = create(:manufacturer)
    sign_in @user

    assert_api_response :post, 200, body: {name: "Enterprise", manufacturerId: manufacturer.id} do
      assert_equal "Enterprise", parsed_body["name"]
    end
  end

  test "POST /models returns 401 when not signed in" do
    manufacturer = create(:manufacturer)

    assert_api_response :post, 401, body: {name: "x", manufacturerId: manufacturer.id}
  end

  test "POST /models returns 403 for admin without access" do
    manufacturer = create(:manufacturer)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", manufacturerId: manufacturer.id}
  end

  # GET /models
  test "GET /models lists models" do
    create_list(:model, 10)
    sign_in @user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /models filters by nameCont query" do
    models = create_list(:model, 10)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /models honours perPage and totals" do
    create_list(:model, 10)
    sign_in @user

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
      assert_equal 5, parsed_body.dig("meta", "pagination", "totalPages")
    end
  end

  test "GET /models returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /models returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /models/:id
  test "DELETE /models/:id destroys the model" do
    model = create(:model)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: model.id}
  end

  test "DELETE /models/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /models/:id returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :delete, 401, path_params: {id: model.id}
  end

  test "DELETE /models/:id returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: model.id}
  end

  # GET /models/:id
  test "GET /models/:id returns the model" do
    model = create(:model)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: model.id}
  end

  test "GET /models/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /models/:id returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :get, 401, path_params: {id: model.id}
  end

  test "GET /models/:id returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: model.id}
  end

  # PUT /models/:id
  test "PUT /models/:id updates the model" do
    model = create(:model)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: model.id}, body: {name: "Enterprise A"} do
      assert_equal "Enterprise A", parsed_body["name"]
    end
  end

  test "PUT /models/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /models/:id returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :put, 401, path_params: {id: model.id}, body: {name: "x"}
  end

  test "PUT /models/:id returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: model.id}, body: {name: "x"}
  end
end
