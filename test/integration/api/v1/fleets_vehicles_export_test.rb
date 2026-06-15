# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsVehiclesExportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/vehicles/export" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehiclesExport"
      tags "Fleets"
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
        schema type: :array, items: {"$ref": "#/components/schemas/FleetVehicleExport"}
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

  test "GET /fleets/:slug/vehicles/export returns vehicle exports" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body.count
    end
  end

  test "GET /fleets/:slug/vehicles/export filters by modelNameCont" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"modelNameCont" => @fleet.models.first.name}} do
      assert_equal 1, parsed_body.count
    end
  end

  test "GET /fleets/:slug/vehicles/export is accessible to a non-admin member" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body.count
    end
  end

  test "GET /fleets/:slug/vehicles/export returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/vehicles/export with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
