# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FeaturesToggleSelfServiceTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/toggle-self-service" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Toggle Feature Self-Service") do
      operationId "toggleAdminFeatureSelfService"
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
    Flipper.add("TestFeature")
  end

  test "PUT /features/:id/toggle-self-service toggles the flag" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}
  end

  test "PUT /features/:id/toggle-self-service returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}
  end

  test "PUT /features/:id/toggle-self-service returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}
  end

  test "PUT /features/:id/toggle-self-service returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}
  end
end
