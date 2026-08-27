# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesEnablePercentageOfTimeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/enable-percentage-of-time" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Enable Feature for Percentage of Time") do
      operationId "enableAdminFeaturePercentageOfTime"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::Admin::V1::Schemas::Inputs::FeaturePercentageInput

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

  test "PUT /features/:id/enable-percentage-of-time sets a percentage" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}, body: {percentage: 50}
  end

  test "PUT /features/:id/enable-percentage-of-time returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}, body: {percentage: 50}
  end

  test "PUT /features/:id/enable-percentage-of-time returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}, body: {percentage: 50}
  end

  test "PUT /features/:id/enable-percentage-of-time returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}, body: {percentage: 50}
  end
end
