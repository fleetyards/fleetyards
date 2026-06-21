# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsShipsExpandFromModelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships/{id}/expand-from-model" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventTeamId", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    post("Expand ship slots from model positions") do
      operationId "expandFleetEventShipFromModel"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid},
          positionIds: {type: :array, items: {type: :string, format: :uuid}}
        },
        required: %w[modelId]
      }

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventShip"
      end

      response(422, "no new positions to add") do
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
    @model = create(:model)
    @ship = create(:fleet_event_ship, fleet_event_team: @team)
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships/:id/expand-from-model expands slots" do
    create(:model_position, model: @model)
    sign_in @admin

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      body: {modelId: @model.id}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships/:id/expand-from-model returns 422 with no new positions" do
    sign_in @admin

    assert_api_response :post, 422,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      body: {modelId: @model.id}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships/:id/expand-from-model with OAuth bearer token" do
    create(:model_position, model: @model)

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {modelId: @model.id}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships/:id/expand-from-model returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {modelId: @model.id}
  end

  test "POST /fleets/:slug/events/:slug/teams/:id/ships/:id/expand-from-model returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug, fleetEventTeamId: @team.id, id: @ship.id},
      body: {modelId: @model.id}
  end
end
