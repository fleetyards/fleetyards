# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Show Fleet Event") do
      operationId "fleetEvent"
      tags "Fleet Events"
      produces "application/json"

      parameter name: :occurrence, in: :query, schema: {type: :string}, required: false,
        description: "ISO-8601 date scoping the response to a single occurrence of a recurring event"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"
      end

      response(404, "not found") do
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
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
  end

  test "GET /fleets/:slug/events/:slug returns the event" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug} do
      assert_equal @fleet_event.title, parsed_body["title"]
      assert_kind_of Array, parsed_body["teams"]
    end
  end

  test "GET /fleets/:slug/events/:slug with occurrence scopes the response" do
    recurring = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: recurring.slug},
      params: {occurrence: "2026-05-21"} do
      assert_equal "2026-05-21", parsed_body["occurrenceDate"]
      assert_includes parsed_body["startsAt"], "2026-05-21"
    end
  end

  test "GET /fleets/:slug/events/:slug returns 404 when event missing" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: "missing-event"}
  end

  test "GET /fleets/:slug/events/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/events/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/events/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug}
  end
end
