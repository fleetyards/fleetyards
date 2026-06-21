# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsShipsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships/sort" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventTeamId", in: :path, schema: {type: :string}

    put("Sort event ships") do
      operationId "sortFleetEventShips"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {
        type: :object,
        properties: {sorting: {type: :array, items: {type: :string, format: :uuid}}},
        required: %w[sorting]
      }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
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
    @ships = create_list(:fleet_event_ship, 3, fleet_event_team: @team)
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/sort sorts ships" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      body: {sorting: @ships.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/sort with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {sorting: @ships.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/sort returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {sorting: @ships.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/events/:slug/teams/:id/ships/sort returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id},
      body: {sorting: @ships.reverse.map(&:id)}
  end
end
