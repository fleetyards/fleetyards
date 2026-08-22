# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesSelfServiceScopeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/self-service-scope" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Set Feature Self-Service Scope") do
      operationId "updateAdminFeatureSelfServiceScope"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FeatureSelfServiceScopeInput"}

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
    Flipper.add("TestFeature")
  end

  test "PUT /features/:id/self-service-scope moves the toggle to a fleet's settings" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}, body: {scope: "fleet"} do
      assert_equal "fleet", FeatureSetting.find_by(feature_name: "TestFeature").self_service_scope
      assert_equal "fleet", parsed_body["selfServiceScope"]
    end
  end

  test "PUT /features/:id/self-service-scope leaves the self-service decision alone" do
    FeatureSetting.create!(feature_name: "TestFeature", self_service: true)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}, body: {scope: "fleet"} do
      assert FeatureSetting.find_by(feature_name: "TestFeature").self_service,
        "where the toggle lives is a separate question from whether there is one"
    end
  end

  test "PUT /features/:id/self-service-scope records a scope before a toggle exists" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}, body: {scope: "fleet"} do
      setting = FeatureSetting.find_by(feature_name: "TestFeature")

      assert_not_nil setting, "the surface can be settled before the toggle is handed out"
      assert_not setting.self_service
    end
  end

  test "PUT /features/:id/self-service-scope returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}, body: {scope: "fleet"}
  end

  test "PUT /features/:id/self-service-scope returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}, body: {scope: "fleet"}
  end

  test "PUT /features/:id/self-service-scope returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}, body: {scope: "fleet"}
  end
end
