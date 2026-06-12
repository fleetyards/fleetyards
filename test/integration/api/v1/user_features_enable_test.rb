# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::UserFeaturesEnableTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/user-features/{id}/enable" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Enable User Feature") do
      operationId "enableUserFeature"
      tags "UserFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/UserFeature"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema type: :object, properties: {code: {type: :string}, message: {type: :string}}
      end
    end
  end

  setup do
    @user = create(:user)
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service: true)
  end

  test "PUT /user-features/:id/enable enables the feature for the signed-in user" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}
  end

  test "PUT /user-features/:id/enable with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["profile:write"])

    assert_api_response :put, 200,
      path_params: {id: "TestFeature"},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /user-features/:id/enable returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :put, 401,
      path_params: {id: "TestFeature"},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /user-features/:id/enable returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}
  end

  test "PUT /user-features/:id/enable returns 403 for non-self-service feature" do
    Flipper.add("NonSelfServiceFeature")
    sign_in @user

    assert_api_response :put, 403, path_params: {id: "NonSelfServiceFeature"}
  end
end
