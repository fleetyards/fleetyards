# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsCancelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/cancel" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Cancel Fleet Event") do
      operationId "cancelFleetEvent"
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

  test "PUT /fleets/:slug/events/:slug/cancel transitions to cancelled" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug} do
      assert_equal "cancelled", parsed_body["status"]
    end
  end

  test "PUT /fleets/:slug/events/:slug/cancel with OAuth bearer token" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "PUT /fleets/:slug/events/:slug/cancel returns 401 for OAuth token with wrong scope" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "PUT /fleets/:slug/events/:slug/cancel returns 401 when not signed in" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end
end
