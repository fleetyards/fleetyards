# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    delete("Delete Fleet Squadron") do
      operationId "destroyFleetSquadron"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - an officer does not delete a squadron") do
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
    @officer = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], officers: [@officer])
    @squadron = create(:fleet_squadron, fleet: @fleet)
  end

  test "DELETE /fleets/:slug/squadrons/:slug removes the squadron" do
    sign_in @admin

    assert_difference -> { FleetSquadron.count }, -1 do
      assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
    end
  end

  # Disbanding a squadron takes nobody out of the fleet.
  test "DELETE /fleets/:slug/squadrons/:slug leaves the fleet memberships alone" do
    membership = create(:fleet_membership, :accepted, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
    sign_in @admin

    assert_difference -> { FleetSquadronMembership.count }, -1 do
      assert_no_difference -> { FleetMembership.kept.count } do
        assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
      end
    end
  end

  test "DELETE /fleets/:slug/squadrons/:slug returns 403 for an officer" do
    sign_in @officer

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  test "DELETE /fleets/:slug/squadrons/:slug returns 404 for an unknown squadron" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {fleetSlug: @fleet.slug, slug: "no-such-wing"}
  end

  test "DELETE /fleets/:slug/squadrons/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  test "DELETE /fleets/:slug/squadrons/:slug with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
