# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UserFeaturesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/user-features" do
    get("User Feature Flags") do
      operationId "userFeatures"
      tags "UserFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/UserFeature"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service: true)
  end

  test "GET /user-features lists self-service features for the signed-in user" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert_equal "TestFeature", parsed_body.first["name"]
    end
  end

  test "GET /user-features with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["profile:write"])

    assert_api_response :get, 200, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /user-features returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :get, 401, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /user-features returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /user-features excludes globally enabled features" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert_empty parsed_body
    end
  end
end
