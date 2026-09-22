# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsStatsModelsBySizeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/models-by-size" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Stats - Models by Size") do
      operationId "fleetModelsBySize"
      tags "FleetStats"

      # The charts count the same vehicles the metrics row above them does, so
      # they take the same filter.
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::PieChartStatsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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

  test "GET /fleets/:slug/stats/models-by-size returns chart data" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  # The charts read `@fleet.vehicles` directly until now, so a squadron picked
  # on the stats page narrowed the metrics row and left every chart under it
  # describing the whole fleet.
  test "GET /fleets/:slug/stats/models-by-size follows the squadron filter" do
    pilot = create(:user, vehicle_count: 2)
    membership = create(:fleet_membership, :accepted, fleet: @fleet, user: pilot)
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: membership)
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/stats/models-by-size?q[squadronSlugIn][]=#{squadron.slug}"

    assert_response :success
    narrowed = JSON.parse(response.body).sum { |slice| slice["y"] }

    get "/api/v1/fleets/#{@fleet.slug}/stats/models-by-size"

    assert_response :success
    whole = JSON.parse(response.body).sum { |slice| slice["y"] }

    assert_equal 2, narrowed
    assert_equal 5, whole
  end

  test "GET /fleets/:slug/stats/models-by-size returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/models-by-size with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
