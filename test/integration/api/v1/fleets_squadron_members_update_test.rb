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

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - a plain member cannot update squadron membership") do
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
end
