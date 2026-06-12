# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsStatsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Vehicles Stats") do
      operationId "fleetVehiclesStats"
      tags "FleetStats"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      # Description preserved verbatim from the original RSpec spec
      # (which used the unusual "successful" text for a 404).
      response(404, "successful") do
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

  test "GET /fleets/:slug/stats/vehicles returns vehicle stats" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/vehicles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/vehicles with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
