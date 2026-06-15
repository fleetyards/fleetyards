# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsVehiclesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, schema: {type: :boolean}, required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetVehicles"
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
    @admin = create(:user, vehicle_count: 2)
    @member = create(:user, vehicle_count: 1)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /fleets/:slug/vehicles lists fleet vehicles" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles filters by modelNameCont" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"modelNameCont" => @fleet.models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles honours perPage" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles honours grouped flag" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {grouped: true} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles works for members" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/vehicles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/vehicles with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
