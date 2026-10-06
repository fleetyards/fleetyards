# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRequestsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/requests/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username of the member who asked"

    delete("Withdraw or decline a Fleet Squadron Request") do
      operationId "destroyFleetSquadronRequest"
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

      response(403, "forbidden - somebody else's request, and not the roster's to answer") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @requester = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@member, @requester])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_request, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by(user: @requester))
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug, username: @requester.username}
  end

  test "DELETE withdraws the member's own request" do
    sign_in @requester

    assert_api_response :delete, 204, path_params: path_params do
      assert_empty @squadron.fleet_squadron_requests
    end
  end

  test "DELETE declines a request for whoever manages the roster" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: path_params do
      assert_empty @squadron.fleet_squadron_requests
    end
  end

  test "DELETE is refused to another member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: path_params

    assert_equal 1, @squadron.fleet_squadron_requests.count
  end

  test "DELETE is not found without a request" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: path_params.merge(username: @member.username)
  end

  test "DELETE needs a session" do
    assert_api_response :delete, 401, path_params: path_params
  end
end
