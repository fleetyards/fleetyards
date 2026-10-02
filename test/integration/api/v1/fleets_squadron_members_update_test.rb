# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronMembersUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    put("Update Fleet Squadron Member") do
      operationId "updateFleetSquadronMember"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronMemberUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(400, "bad request - the squadron already has a Leader") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - neither the fleet role nor the squadron rank outranks this member") do
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
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    @squadron_membership = create(
      :fleet_squadron_membership,
      fleet_squadron: @squadron,
      fleet_membership: membership
    )
  end

  def path_params(username = @member.username)
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug, username: username}
  end

  test "PUT squadron member updates the squadron joined date" do
    sign_in @admin

    assert_api_response :put, 204,
      path_params: path_params,
      body: {createdAt: "2024-05-14"}

    assert_equal Date.new(2024, 5, 14), @squadron_membership.reload.created_at.to_date
  end

  test "PUT squadron member date update is allowed for an officer" do
    sign_in @officer

    assert_api_response :put, 204,
      path_params: path_params,
      body: {createdAt: "2024-05-14"}
  end

  test "PUT squadron member date update is forbidden for a plain member" do
    sign_in @member

    assert_api_response :put, 403,
      path_params: path_params,
      body: {createdAt: "2024-05-14"}
  end

  def rank(key)
    @fleet.fleet_squadron_roles.find_by!(key:)
  end

  # A plain fleet member holding `key` in @squadron.
  def squadron_ranked(key)
    user = create(:user)
    membership = create(:fleet_membership, :accepted, fleet: @fleet, user:)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership, fleet_squadron_role: rank(key))
    user
  end

  test "PUT squadron member changes the rank for a fleet officer" do
    sign_in @officer

    assert_api_response :put, 204,
      path_params: path_params,
      body: {fleetSquadronRoleId: rank("leader").id}

    assert_equal "leader", @squadron_membership.reload.fleet_squadron_role.key
  end

  test "PUT squadron member lets a squadron Leader appoint an officer" do
    sign_in squadron_ranked("leader")

    assert_api_response :put, 204,
      path_params: path_params,
      body: {fleetSquadronRoleId: rank("officer").id}

    assert_equal "officer", @squadron_membership.reload.fleet_squadron_role.key
  end

  test "PUT squadron member refuses a squadron Officer changing ranks" do
    sign_in squadron_ranked("officer")

    assert_api_response :put, 403,
      path_params: path_params,
      body: {fleetSquadronRoleId: rank("officer").id}
  end

  test "PUT squadron member refuses a second Leader" do
    squadron_ranked("leader")
    sign_in @admin

    assert_api_response :put, 400,
      path_params: path_params,
      body: {fleetSquadronRoleId: rank("leader").id}

    assert_equal "member", @squadron_membership.reload.fleet_squadron_role.key
  end
end
