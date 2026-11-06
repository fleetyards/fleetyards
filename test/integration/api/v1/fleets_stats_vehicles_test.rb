# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsStatsVehiclesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Vehicles Stats") do
      operationId "fleetVehiclesStats"
      tags "FleetStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetVehiclesStats"
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      # Description preserved verbatim from the original RSpec spec
      # (which used the unusual "successful" text for a 404).
      response(404, "successful") do
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

  test "GET /fleets/:slug/stats/vehicles counts a looted ship as owned but not as money spent" do
    sign_in @admin
    user = @admin
    fleet = @fleet
    before = {}

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      before = {total: parsed_body["total"], money: parsed_body.dig("metrics", "totalMoney")}
    end

    create(:vehicle, user:, public: true, bought_via: :reward_or_loot, model: create(:model, pledge_price: 50),
      model_module_ids: [create(:model_module, pledge_price: 30).id],
      model_upgrade_ids: [create(:model_upgrade, pledge_price: 20).id])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal before[:total] + 1, parsed_body["total"]
      assert_equal before[:money], parsed_body.dig("metrics", "totalMoney")
    end
  end

  test "GET /fleets/:slug/stats/vehicles returns vehicle stats" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/vehicles returns 404 for a non-member" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
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
