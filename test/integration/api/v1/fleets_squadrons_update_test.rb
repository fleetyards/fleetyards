# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    put("Update Fleet Squadron") do
      operationId "updateFleetSquadron"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadron
      end

      response(400, "bad request - duplicate name") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - an officer does not rename a squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @officer = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer])
    @squadron = create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
  end

  test "PUT /fleets/:slug/squadrons/:slug makes a squadron a team" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {team: true} do
      assert parsed_body["team"]
    end
  end

  # Nothing would ever repair a rule that was already broken when the flag came
  # off, so the change is refused rather than the state allowed.
  test "PUT /fleets/:slug/squadrons/:slug refuses to unmake a team over a shared member" do
    @squadron.update!(team: true)
    other = create(:fleet_squadron, fleet: @fleet, name: "Mining")
    membership = create(:fleet_membership, :accepted, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: membership)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {team: false}
  end

  test "PUT /fleets/:slug/squadrons/:slug renames the squadron and moves its slug" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Escort Wing"} do
      assert_equal "Escort Wing", parsed_body["name"]
      assert_equal "escort-wing", parsed_body["slug"]
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug updates the colour and description" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {color: "#0AF", description: "Escort duty"} do
      assert_equal "#0af", parsed_body["color"]
      assert_equal "Escort duty", parsed_body["description"]
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug sets and clears the Discord channel" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {discordChannelId: "123456789012345678"} do
      assert_equal "123456789012345678", parsed_body["discordChannelId"]
    end

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {discordChannelId: ""} do
      assert_nil parsed_body["discordChannelId"]
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 400 for a Discord channel that is not an id" do
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {discordChannelId: "#general"}
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 400 for a name another squadron holds" do
    create(:fleet_squadron, fleet: @fleet, name: "Mining Division")
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Mining Division"}
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 403 for an officer" do
    sign_in @officer

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Officer Wing"}
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Anon Wing"}
  end

  test "PUT /fleets/:slug/squadrons/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {description: "Updated by token"}
  end
end
