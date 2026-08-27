# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesToggleFleetSelfServiceTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/toggle-fleet-self-service" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Toggle Feature Fleet Self-Service") do
      operationId "toggleAdminFeatureFleetSelfService"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feature
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:features])
    Flipper.add("TestFeature")
  end

  test "PUT /features/:id/toggle-fleet-self-service hands a fleet's admins the switch" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"} do
      assert FeatureSetting.fleet_toggleable?("TestFeature")
      assert_not FeatureSetting.user_toggleable?("TestFeature"),
        "a fleet switch without a personal one is what the old exclusive scope could not say"
      assert parsed_body["selfServiceFleet"]
    end
  end

  test "PUT /features/:id/toggle-fleet-self-service takes the switch back" do
    FeatureSetting.create!(feature_name: "TestFeature", self_service_fleet: true)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"} do
      assert_not FeatureSetting.fleet_toggleable?("TestFeature")
    end
  end

  test "PUT /features/:id/toggle-fleet-self-service returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}
  end

  test "PUT /features/:id/toggle-fleet-self-service returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}
  end

  test "PUT /features/:id/toggle-fleet-self-service returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}
  end
end
