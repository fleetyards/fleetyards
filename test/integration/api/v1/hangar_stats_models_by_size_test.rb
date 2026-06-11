# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::HangarStatsModelsBySizeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/stats/models-by-size" do
    get("Hangar Stats - Models by Size") do
      operationId "hangarModelsBySize"
      tags "HangarStats"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /hangar/stats/models-by-size returns chart data" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /hangar/stats/models-by-size returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/stats/models-by-size with OAuth bearer token" do
    user = create(:user, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
