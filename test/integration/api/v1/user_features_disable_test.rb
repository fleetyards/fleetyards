# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UserFeaturesDisableTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/user-features/{id}/disable" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Disable User Feature") do
      operationId "disableUserFeature"
      tags "UserFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::UserFeature
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service_user: true)
    Flipper.feature("TestFeature").enable_actor(@user)
  end

  test "PUT /user-features/:id/disable disables the feature for the signed-in user" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}
  end

  test "PUT /user-features/:id/disable with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["profile:write"])

    assert_api_response :put, 200,
      path_params: {id: "TestFeature"},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /user-features/:id/disable returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :put, 401,
      path_params: {id: "TestFeature"},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /user-features/:id/disable returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}
  end

  test "PUT /user-features/:id/disable returns 403 for non-self-service feature" do
    Flipper.add("NonSelfServiceFeature")
    sign_in @user

    assert_api_response :put, 403, path_params: {id: "NonSelfServiceFeature"}
  end

  test "PUT /user-features/:id/disable disables a fleet-scoped feature for the user alone" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    Flipper.enable_actor("FleetWideFeature", @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "FleetWideFeature"} do
      assert_not Flipper.enabled?("FleetWideFeature", @user)
    end
  end

  test "PUT /user-features/:id/disable returns 403 when the user's fleet enabled it" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    fleet = create(:fleet, members: [@user])
    Flipper.enable_actor("FleetWideFeature", fleet)
    sign_in @user

    assert_api_response :put, 403, path_params: {id: "FleetWideFeature"} do
      assert Flipper.enabled?("FleetWideFeature", fleet),
        "a member cannot override what their fleet turned on, so the API refuses " \
        "rather than reporting a change they will not see"
    end
  end

  test "PUT /user-features/:id/disable ignores a fleet the user has only been invited to" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    fleet = create(:fleet)
    create(:fleet_membership, :invited, fleet:, user: @user)
    Flipper.enable_actor("FleetWideFeature", fleet)
    Flipper.enable_actor("FleetWideFeature", @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "FleetWideFeature"} do
      assert_not Flipper.enabled?("FleetWideFeature", @user),
        "a pending invitation does not hand the fleet control of the user's toggle"
    end
  end

  test "PUT /user-features/:id/disable returns 403 when a group the user is in enabled it" do
    tester = create(:user, :tester)
    Flipper.enable_group("TestFeature", :testers)
    sign_in tester

    assert_api_response :put, 403, path_params: {id: "TestFeature"} do
      assert Flipper.enabled?("TestFeature", tester),
        "clearing the personal gate would not take the group's grant away, so the API refuses " \
        "rather than reporting a change the user will not see"
    end
  end
end
