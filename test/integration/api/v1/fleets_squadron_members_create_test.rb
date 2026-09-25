# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronMembersCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    post("Add Fleet Squadron Member") do
      operationId "createFleetSquadronMember"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronMemberCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::FleetMember
      end

      response(400, "bad request - already in this squadron") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - a plain member does not post people to a squadron") do
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
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "POST squadron members adds a member" do
    sign_in @admin

    assert_difference -> { FleetSquadronMembership.count }, 1 do
      assert_api_response :post, 201, path_params: path_params, body: {username: @member.username} do
        assert_equal @member.username, parsed_body["username"]
      end
    end
  end

  # The officer role is seeded with `fleet:squadrons:members:manage` and
  # nothing else, so this is the one write it may make.
  test "POST squadron members is allowed for an officer" do
    sign_in @officer

    assert_api_response :post, 201, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members returns 403 for a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members returns 400 when the member is already in the squadron" do
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
    sign_in @admin

    assert_api_response :post, 400, path_params: path_params, body: {username: @member.username}
  end

  # A team takes anybody, however many they are already on.
  test "POST squadron members adds one member to several teams" do
    @squadron.update!(team: true)
    other = create(:fleet_squadron, fleet: @fleet, team: true)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: membership)
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members returns 400 for a member who already has a squadron" do
    other = create(:fleet_squadron, fleet: @fleet)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: membership)
    sign_in @admin

    assert_api_response :post, 400, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members adds a member who is only on teams" do
    other = create(:fleet_squadron, fleet: @fleet, team: true)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: membership)
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members returns 404 for somebody outside the fleet" do
    sign_in @admin

    assert_api_response :post, 404, path_params: path_params, body: {username: create(:user).username}
  end

  test "POST squadron members returns 404 for a member who has not accepted" do
    invited = create(:user)
    create(:fleet_membership, :invited, fleet: @fleet, user: invited)
    sign_in @admin

    assert_api_response :post, 404, path_params: path_params, body: {username: invited.username}
  end

  test "POST squadron members returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: path_params, body: {username: @member.username}
  end

  test "POST squadron members with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: path_params,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {username: @member.username}
  end
end
