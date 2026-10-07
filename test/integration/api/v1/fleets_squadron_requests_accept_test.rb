# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRequestsAcceptTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/requests/{username}/accept" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username of the member who asked"

    put("Accept a Fleet Squadron Request") do
      operationId "acceptFleetSquadronRequest"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
      end

      response(400, "bad request - the member joined another squadron since asking") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - only whoever manages the roster answers requests") do
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
    @membership = @fleet.fleet_memberships.kept.find_by(user: @requester)
    create(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)
  end

  def path_params(username = @requester.username)
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug, username:}
  end

  test "PUT accept adds the member and closes the request" do
    sign_in @admin

    assert_api_response :put, 204, path_params: path_params do
      assert @squadron.fleet_squadron_memberships.exists?(fleet_membership: @membership)
      assert_empty @squadron.fleet_squadron_requests
    end
  end

  test "PUT accept keeps the request when the member is in another squadron" do
    other = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: @membership)
    # Joining closes every request, so only one that predates the rule is left.
    build(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership).save!(validate: false)
    sign_in @admin

    assert_api_response :put, 400, path_params: path_params do
      assert_equal 1, @squadron.fleet_squadron_requests.count
    end
  end

  test "PUT accept is refused to an ordinary member" do
    sign_in @member

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT accept is not found without a request" do
    sign_in @admin

    assert_api_response :put, 404, path_params: path_params(@member.username)
  end

  test "PUT accept needs a session" do
    assert_api_response :put, 401, path_params: path_params
  end
end
