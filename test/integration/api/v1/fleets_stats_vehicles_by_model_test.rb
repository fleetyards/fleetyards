# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsStatsVehiclesByModelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/vehicles-by-model" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Stats - Vehicles by Model") do
      operationId "fleetVehiclesByModel"
      tags "FleetStats"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
    @admin = create(:user, vehicle_count: 3)
    @fleet = create(:fleet, admins: [@admin])
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /fleets/:slug/stats/vehicles-by-model returns chart data" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/vehicles-by-model returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/vehicles-by-model with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
