# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/sort" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    put("Sort Fleet Squadrons") do
      operationId "sortFleetSquadrons"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronSortInput

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

  test "PUT /fleets/:slug/squadrons/sort writes the order it is given" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@third.id, @first.id, @second.id]} do
      assert_equal [@third, @first, @second].map(&:name),
        @fleet.fleet_squadrons.reload.map(&:name)
    end
  end

  # Every cached fragment that lists a squadron keys on it, and the order is
  # part of what those fragments show.
  test "PUT /fleets/:slug/squadrons/sort touches the squadrons it moves" do
    @third.update_column(:updated_at, 1.day.ago)
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@third.id, @first.id, @second.id]}

    assert_operator @third.reload.updated_at, :>, 1.minute.ago
  end

  # The order is one list, so a squadron left out of the call keeps the place it
  # had rather than collapsing to the front with everything else.
  test "PUT /fleets/:slug/squadrons/sort leaves out what it was not sent" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@second.id, @first.id]} do
      assert_equal %w[Bravo Alpha Charlie], @fleet.fleet_squadrons.reload.map(&:name)
    end
  end

  test "PUT /fleets/:slug/squadrons/sort ignores an id from another fleet" do
    other = create(:fleet_squadron, fleet: create(:fleet))
    sign_in @admin

    assert_api_response :put, 204,
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [other.id]} do
      assert_equal 1, other.reload.position
    end
  end

  test "PUT /fleets/:slug/squadrons/sort is refused to a member" do
    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@third.id]}
  end

  test "PUT /fleets/:slug/squadrons/sort with OAuth bearer token" do
    assert_api_response :put, 204,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@third.id, @first.id, @second.id]}
  end

  test "PUT /fleets/:slug/squadrons/sort returns 401 for a token with the wrong scope" do
    assert_api_response :put, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      path_params: {fleetSlug: @fleet.slug},
      body: {sorting: [@third.id]}
  end
end
