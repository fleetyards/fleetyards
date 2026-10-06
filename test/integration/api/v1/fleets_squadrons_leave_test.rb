# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsLeaveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}/leave" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    delete("Leave Fleet Squadron") do
      operationId "leaveFleetSquadron"
      tags "FleetSquadrons"
      produces "application/json"

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

      response(404, "not found - not in this squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
  end

  test "DELETE leave takes the member out of a squadron, whatever their rank" do
    leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: @membership, fleet_squadron_role: leader)
    sign_in @member

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      refute @squadron.fleet_squadron_memberships.exists?(fleet_membership: @membership)
    end
  end

  test "DELETE leave is not found for a squadron the member is not in" do
    sign_in @member

    assert_api_response :delete, 404, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  test "DELETE leave needs a session" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end
end
