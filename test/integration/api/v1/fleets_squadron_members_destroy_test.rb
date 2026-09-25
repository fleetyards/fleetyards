# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronMembersDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    delete("Remove Fleet Squadron Member") do
      operationId "destroyFleetSquadronMember"
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

      response(403, "forbidden - a plain member does not take people out of a squadron") do
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
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], officers: [@officer], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership)
  end

  def path_params(username = @member.username)
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug, username: username}
  end

  test "DELETE squadron member takes them out of the squadron and leaves the fleet alone" do
    sign_in @admin

    assert_difference -> { FleetSquadronMembership.count }, -1 do
      assert_no_difference -> { FleetMembership.kept.count } do
        assert_api_response :delete, 204, path_params: path_params
      end
    end
  end

  test "DELETE squadron member is allowed for an officer" do
    sign_in @officer

    assert_api_response :delete, 204, path_params: path_params
  end

  test "DELETE squadron member returns 403 for a plain member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: path_params
  end

  test "DELETE squadron member returns 404 when they are not in this squadron" do
    other = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: other)
    sign_in @admin

    assert_api_response :delete, 404, path_params: path_params(other.username)
  end

  test "DELETE squadron member returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: path_params
  end

  test "DELETE squadron member with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: path_params,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
