# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsUnarchiveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/unarchive" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Unarchive Fleet Event") do
      operationId "unarchiveFleetEvent"
      tags "Fleet Events"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"
      end

      response(400, "not archived") do
        schema "$ref": "#/components/schemas/StandardError"
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

  test "PUT /fleets/:slug/events/:slug/unarchive unarchives the event" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    fleet_event.archive!
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug} do
      assert_equal false, parsed_body["archived"]
    end
  end

  test "PUT /fleets/:slug/events/:slug/unarchive returns 400 when event is not archived" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end

  test "PUT /fleets/:slug/events/:slug/unarchive with OAuth bearer token" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    fleet_event.archive!

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "PUT /fleets/:slug/events/:slug/unarchive returns 401 for OAuth token with wrong scope" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    fleet_event.archive!

    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "PUT /fleets/:slug/events/:slug/unarchive returns 401 when not signed in" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    fleet_event.archive!

    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end
end
