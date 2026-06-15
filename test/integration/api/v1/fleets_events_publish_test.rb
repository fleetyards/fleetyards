# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsPublishTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/publish" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Publish Fleet Event") do
      operationId "publishFleetEvent"
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

      response(400, "invalid state transition") do
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

  test "PUT /fleets/:slug/events/:slug/publish transitions to open" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug} do
      assert_equal "open", parsed_body["status"]
    end
    assert_equal "open", fleet_event.reload.status
  end

  test "PUT /fleets/:slug/events/:slug/publish returns 400 for invalid transition" do
    fleet_event = create(:fleet_event, :active, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end

  test "PUT /fleets/:slug/events/:slug/publish with OAuth bearer token" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "PUT /fleets/:slug/events/:slug/publish returns 401 for OAuth token with wrong scope" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "PUT /fleets/:slug/events/:slug/publish returns 401 when not signed in" do
    fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end
end
