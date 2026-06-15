# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsShipsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventTeamId", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update event ship") do
      operationId "updateFleetEventShip"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetEventShipUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventShip"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Destroy event ship") do
      operationId "destroyFleetEventShip"
      tags "Fleet Event Ships"
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
    @ship = create(:fleet_event_ship, fleet_event_team: @team)
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/:id updates the ship" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      body: {classification: "Industrial", description: "Hauling"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {classification: "Industrial", description: "Hauling"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {classification: "Industrial", description: "Hauling"}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      body: {classification: "Industrial", description: "Hauling"}
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id/ships/:id destroys the ship" do
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id}

    assert_raises(ActiveRecord::RecordNotFound) { @ship.reload }
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id/ships/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id/ships/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/events/:slug/teams/:id/ships/:id returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id}
  end
end
