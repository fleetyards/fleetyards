# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesHistoryTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/history" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    get("Feature Change History") do
      operationId "adminFeatureHistory"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FeatureChangesList
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
    FeatureFlagChange.create!(
      feature_name: "TestFeature",
      operation: "enable",
      gate_name: "boolean",
      thing: "true",
      state_after: FeatureFlagChange::STATE_ON,
      source: FeatureFlagChange::SOURCE_ADMIN,
      admin_user: @user
    )
  end

  test "GET /features/:id/history returns the flag's changes" do
    sign_in @user

    assert_api_response :get, 200, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id/history returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "NonExistentFeature"}
  end

  # The one action that outlives its flag. Sync prunes the Flipper feature and
  # every gate with it; feature_name is a plain string so these rows survive, and
  # a 404 here would make that retention pointless.
  test "GET /features/:id/history still serves a pruned feature's history" do
    FeatureFlagChange.create!(
      feature_name: "PrunedFeature",
      operation: "remove",
      state_after: FeatureFlagChange::STATE_OFF,
      source: FeatureFlagChange::SOURCE_SYNC
    )
    assert_not Flipper.exist?("PrunedFeature")

    sign_in @user

    assert_api_response :get, 200, path_params: {id: "PrunedFeature"}
  end

  test "GET /features/:id/history returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id/history returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: "TestFeature"}
  end
end
