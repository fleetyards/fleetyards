# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FeaturesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features" do
    post("Create Feature") do
      operationId "createAdminFeature"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FeatureInput"}

      response(201, "created") do
        schema "$ref": "#/components/schemas/Feature"
      end

      response(422, "invalid") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Features list") do
      operationId "adminFeatures"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Feature"}
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/features/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    delete("Delete Feature") do
      operationId "destroyAdminFeature"
      tags "Features"

      response(204, "deleted")

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

    get("Feature Detail") do
      operationId "adminFeature"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Feature"
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
    @user = create(:admin_user, resource_access: [:features])
  end

  # POST /features
  test "POST /features creates a feature" do
    sign_in @user

    assert_api_response :post, 201, body: {name: "new-feature"}
  end

  test "POST /features returns 422 for blank name" do
    sign_in @user

    assert_api_response :post, 422, body: {name: ""}
  end

  test "POST /features returns 401 when not signed in" do
    assert_api_response :post, 401, body: {name: "new-feature"}
  end

  test "POST /features returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "new-feature"}
  end

  # GET /features
  test "GET /features returns all features" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert parsed_body.first["name"].present?
    end
  end

  test "GET /features returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /features returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /features/:id
  test "DELETE /features/:id removes the feature" do
    Flipper.add("TestFeature")
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: "TestFeature"}
  end

  test "DELETE /features/:id returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "NonExistentFeature"}
  end

  test "DELETE /features/:id returns 401 when not signed in" do
    Flipper.add("TestFeature")

    assert_api_response :delete, 401, path_params: {id: "TestFeature"}
  end

  test "DELETE /features/:id returns 403 for admin without access" do
    Flipper.add("TestFeature")
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: "TestFeature"}
  end

  # GET /features/:id
  test "GET /features/:id returns the feature" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "NonExistentFeature"}
  end

  test "GET /features/:id returns 401 when not signed in" do
    Flipper.enable("TestFeature")

    assert_api_response :get, 401, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id returns 403 for admin without access" do
    Flipper.enable("TestFeature")
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: "TestFeature"}
  end
end
