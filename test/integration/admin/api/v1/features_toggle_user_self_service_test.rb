# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesToggleUserSelfServiceTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/toggle-user-self-service" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Toggle Feature User Self-Service") do
      operationId "toggleAdminFeatureUserSelfService"
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

  test "PUT /features/:id/toggle-user-self-service hands users their own toggle" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"} do
      assert FeatureSetting.user_toggleable?("TestFeature")
      assert_not FeatureSetting.fleet_toggleable?("TestFeature"),
        "the two surfaces are independent, so one switch must not carry the other"
      assert parsed_body["selfServiceUser"]
    end
  end

  test "PUT /features/:id/toggle-user-self-service takes the toggle back" do
    FeatureSetting.create!(feature_name: "TestFeature", self_service_user: true)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"} do
      assert_not FeatureSetting.user_toggleable?("TestFeature")
    end
  end

  test "PUT /features/:id/toggle-user-self-service leaves the fleet toggle alone" do
    FeatureSetting.create!(feature_name: "TestFeature", self_service_fleet: true)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"} do
      assert FeatureSetting.fleet_toggleable?("TestFeature")
      assert FeatureSetting.user_toggleable?("TestFeature")
    end
  end

  test "PUT /features/:id/toggle-user-self-service returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}
  end

  test "PUT /features/:id/toggle-user-self-service returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}
  end

  test "PUT /features/:id/toggle-user-self-service returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}
  end
end
