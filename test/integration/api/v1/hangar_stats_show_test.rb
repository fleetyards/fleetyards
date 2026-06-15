# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarStatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/stats" do
    get("Your Hangar Stats") do
      operationId "hangarStats"
      tags "HangarStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarStats"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /hangar/stats returns the user's hangar stats" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /hangar/stats returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/stats with OAuth bearer token" do
    user = create(:user, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
