# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsShipsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventTeamId", in: :path, schema: {type: :string}

    post("Create event ship") do
      operationId "createFleetEventShip"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetEventShipCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Events::FleetEventShip
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @fleet_event)
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships creates a ship" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      body: {classification: "Combat", minSize: "small"}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {classification: "Combat", minSize: "small"}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {classification: "Combat", minSize: "small"}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      body: {classification: "Combat", minSize: "small"}
  end
end
