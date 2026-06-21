# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update event team") do
      operationId "updateFleetEventTeam"
      tags "Fleet Event Teams"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetEventTeamUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventTeam"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Destroy event team") do
      operationId "destroyFleetEventTeam"
      tags "Fleet Event Teams"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
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
    @team = create(:fleet_event_team, fleet_event: @fleet_event)
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id updates the team" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      body: {title: "Renamed", description: "Updated"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Renamed", description: "Updated"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Renamed", description: "Updated"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      body: {title: "Renamed", description: "Updated"}
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id destroys the team" do
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id}

    assert_raises(ActiveRecord::RecordNotFound) { @team.reload }
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, id: @team.id}
  end
end
