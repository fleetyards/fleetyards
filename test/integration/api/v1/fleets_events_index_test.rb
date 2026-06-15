# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("List Fleet Events") do
      operationId "fleetEvents"
      tags "Fleet Events"
      produces "application/json"

      parameter name: :upcoming, in: :query, schema: {type: :boolean}, required: false
      parameter name: :past, in: :query, schema: {type: :boolean}, required: false
      parameter name: :archived, in: :query, schema: {type: :boolean}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventsList"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/events returns the list" do
    create_list(:fleet_event, 2, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body["items"].size
    end
  end

  test "GET /fleets/:slug/events with OAuth bearer token" do
    create_list(:fleet_event, 1, fleet: @fleet, created_by: @admin)

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/events returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/events returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
