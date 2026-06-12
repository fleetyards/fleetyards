# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsStatsModelCountsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/stats/model-counts" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Stats Model Counts") do
      operationId "fleetModelCounts"
      tags "FleetStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    shared_model = create(:model)
    @shared_one = create(:vehicle, user: @admin, model: shared_model)
    @shared_two = create(:vehicle, user: @admin, model: shared_model)
    @unique = create(:vehicle, user: @admin)
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /fleets/:slug/stats/model-counts returns model counts" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal(
        {@shared_one.model.slug => 2, @unique.model.slug => 1},
        parsed_body["modelCounts"]
      )
    end
  end

  test "GET /fleets/:slug/stats/model-counts filters by modelNameCont" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"modelNameCont" => @shared_one.model.name}} do
      assert_equal({@shared_one.model.slug => 2}, parsed_body["modelCounts"])
    end
  end

  test "GET /fleets/:slug/stats/model-counts returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/stats/model-counts with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
