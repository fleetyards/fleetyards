# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsAdminsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/admins" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Grant per-event admin/moderator role") do
      operationId "createFleetEventAdmin"
      tags "Fleet Event Admins"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetEventAdminCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventAdmin"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @other = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@other])
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
  end

  test "POST /fleets/:slug/events/:slug/admins grants the requested role" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {userId: @other.id, role: "admin"} do
      assert_equal "admin", parsed_body["role"]
    end
  end

  test "POST /fleets/:slug/events/:slug/admins with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {userId: @other.id, role: "admin"}
  end

  test "POST /fleets/:slug/events/:slug/admins returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {userId: @other.id, role: "admin"}
  end

  test "POST /fleets/:slug/events/:slug/admins returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {userId: @other.id, role: "admin"}
  end
end
