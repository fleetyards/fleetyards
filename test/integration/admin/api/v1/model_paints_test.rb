# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelPaintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/model-paints" do
    post("Create Model Paint") do
      operationId "createModelPaint"
      tags "ModelPaints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPaintInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Paints list") do
      operationId "listModelPaints"
      tags "ModelPaints"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPaint.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPaintQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaints"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/model-paints/{id}" do
    parameter name: "id", in: :path, description: "Model Paint id", schema: {type: :string, format: :uuid}

    delete("Destroy Model Paint") do
      operationId "destroyModelPaint"
      tags "ModelPaints"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"
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

    get("Model Paint Detail") do
      operationId "modelPaint"
      tags "ModelPaints"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"
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

    put("Update Model Paint") do
      operationId "updateModelPaint"
      tags "ModelPaints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPaintInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"
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
    @user = create(:admin_user, resource_access: [:model_paints])
  end

  # POST /model-paints
  test "POST /model-paints creates a paint" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 200, body: {name: "Midnight Blue", modelId: model.id} do
      assert_equal "Midnight Blue", parsed_body["name"]
    end
  end

  test "POST /model-paints returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {name: "x", modelId: model.id}
  end

  test "POST /model-paints returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x", modelId: model.id}
  end

  # GET /model-paints
  test "GET /model-paints lists paints" do
    create_list(:model_paint, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /model-paints filters by nameCont query" do
    paints = create_list(:model_paint, 3)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => paints.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /model-paints paginates with perPage" do
    create_list(:model_paint, 3)
    sign_in @user

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
      assert_equal 2, parsed_body.dig("meta", "pagination", "totalPages")
    end
  end

  test "GET /model-paints returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /model-paints returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /model-paints/:id
  test "DELETE /model-paints/:id destroys the paint" do
    paint = create(:model_paint)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: paint.id}
  end

  test "DELETE /model-paints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /model-paints/:id returns 401 when not signed in" do
    paint = create(:model_paint)

    assert_api_response :delete, 401, path_params: {id: paint.id}
  end

  test "DELETE /model-paints/:id returns 403 for admin without access" do
    paint = create(:model_paint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: paint.id}
  end

  # GET /model-paints/:id
  test "GET /model-paints/:id returns the paint" do
    paint = create(:model_paint)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: paint.id}
  end

  test "GET /model-paints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /model-paints/:id returns 401 when not signed in" do
    paint = create(:model_paint)

    assert_api_response :get, 401, path_params: {id: paint.id}
  end

  test "GET /model-paints/:id returns 403 for admin without access" do
    paint = create(:model_paint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: paint.id}
  end

  # PUT /model-paints/:id
  test "PUT /model-paints/:id updates the paint" do
    paint = create(:model_paint)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: paint.id}, body: {name: "Updated Paint"} do
      assert_equal "Updated Paint", parsed_body["name"]
    end
  end

  test "PUT /model-paints/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /model-paints/:id returns 401 when not signed in" do
    paint = create(:model_paint)

    assert_api_response :put, 401, path_params: {id: paint.id}, body: {name: "x"}
  end

  test "PUT /model-paints/:id returns 403 for admin without access" do
    paint = create(:model_paint)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: paint.id}, body: {name: "x"}
  end
end
