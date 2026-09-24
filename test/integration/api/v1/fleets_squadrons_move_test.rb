# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsMoveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}/move" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    put("Move Fleet Squadron") do
      operationId "moveFleetSquadron"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronMoveInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - a member does not arrange the list") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @first = create(:fleet_squadron, fleet: @fleet, name: "Alpha")
    @second = create(:fleet_squadron, fleet: @fleet, name: "Bravo")
    @third = create(:fleet_squadron, fleet: @fleet, name: "Charlie")
  end

  def names
    @fleet.fleet_squadrons.reload.map(&:name)
  end

  test "PUT /fleets/:slug/squadrons/:slug/move puts a squadron at the front" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @third.slug},
      body: {position: 0} do
      assert_equal %w[Charlie Alpha Bravo], names
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug/move puts a squadron between two others" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @first.slug},
      body: {position: 1} do
      assert_equal %w[Bravo Alpha Charlie], names
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug/move past the end puts a squadron last" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @first.slug},
      body: {position: 10} do
      assert_equal %w[Bravo Charlie Alpha], names
    end
  end

  # One row is written, and it is touched: every cached fragment that lists a
  # squadron keys on it, and the order is part of what those fragments show.
  test "PUT /fleets/:slug/squadrons/:slug/move leaves the others alone and touches the one it moves" do
    [@first, @second, @third].each { |squadron| squadron.update_column(:updated_at, 1.day.ago) }
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @third.slug},
      body: {position: 0}

    assert_operator @third.reload.updated_at, :>, 1.minute.ago
    assert_operator @first.reload.updated_at, :<, 1.hour.ago
    assert_operator @second.reload.updated_at, :<, 1.hour.ago
  end

  test "PUT /fleets/:slug/squadrons/:slug/move does not reach another fleet's squadron" do
    other = create(:fleet_squadron, fleet: create(:fleet))
    sign_in @admin

    assert_api_response :put, 404,
      path_params: {fleetSlug: @fleet.slug, slug: other.slug},
      body: {position: 0}
  end

  test "PUT /fleets/:slug/squadrons/:slug/move is refused to a member" do
    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, slug: @third.slug},
      body: {position: 0}
  end

  test "PUT /fleets/:slug/squadrons/:slug/move with OAuth bearer token" do
    assert_api_response :put, 204,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      path_params: {fleetSlug: @fleet.slug, slug: @third.slug},
      body: {position: 0}
  end

  test "PUT /fleets/:slug/squadrons/:slug/move returns 401 for a token with the wrong scope" do
    assert_api_response :put, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      path_params: {fleetSlug: @fleet.slug, slug: @third.slug},
      body: {position: 0}
  end
end
