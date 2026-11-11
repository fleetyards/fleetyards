# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}

    post("Create event team") do
      operationId "createFleetEventTeam"
      tags "Fleet Event Teams"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetEventTeamCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Events::FleetEventTeam
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
  end

  test "POST /fleets/:slug/events/:slug/teams creates a team" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "Strike Team", description: "Heavy fighters"} do
      assert_equal "Strike Team", parsed_body["title"]
    end
  end

  test "POST /fleets/:slug/events/:slug/teams with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Strike Team", description: "Heavy fighters"}
  end

  test "POST /fleets/:slug/events/:slug/teams returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Strike Team", description: "Heavy fighters"}
  end

  test "POST /fleets/:slug/events/:slug/teams returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "Strike Team", description: "Heavy fighters"}
  end

  test "POST /fleets/:slug/events/:slug/teams from a squadron takes its name and description" do
    squadron = create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing", short_description: "Interceptors")
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "", fleetSquadronId: squadron.id} do
      assert_equal "Alpha Wing", parsed_body["title"]
      assert_equal "Interceptors", parsed_body["description"]
      assert_equal squadron.id, parsed_body.dig("fleetSquadron", "id")
    end
  end

  test "POST /fleets/:slug/events/:slug/teams from a team keeps the title given" do
    team = create(:fleet_squadron, fleet: @fleet, name: "Salvage Crew", team: true)
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "Salvage -- Wrecks", fleetSquadronId: team.id} do
      assert_equal "Salvage -- Wrecks", parsed_body["title"]
      assert parsed_body.dig("fleetSquadron", "team")
    end
  end

  # Plain posts rather than the DSL: declaring a 400 would replace the
  # auto-injected SchemaValidationError response.
  test "POST /fleets/:slug/events/:slug/teams refuses another fleet's squadron" do
    foreign = create(:fleet_squadron)
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/teams", params: {title: "Strike Team", fleetSquadronId: foreign.id}, as: :json

    assert_response :bad_request
  end

  test "refuses a squadron id that names no squadron" do
    sign_in @admin

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@fleet_event.slug}/teams", params: {title: "Strike Team", fleetSquadronId: SecureRandom.uuid}, as: :json

    assert_response :bad_request
  end
end
