# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRequestsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/requests" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron Requests List") do
      operationId "fleetSquadronRequests"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronRequestsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - only whoever manages the roster answers requests") do
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
    @request = create(:fleet_squadron_request, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by(user: @requester))
  end

  def path_params
    {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug}
  end

  test "GET requests lists who asked to join" do
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@requester.username], parsed_body.map { |entry| entry.dig("member", "username") }
    end
  end

  test "GET requests leaves out somebody who has since left the fleet" do
    @request.fleet_membership.discard!
    sign_in @admin

    assert_api_response :get, 200, path_params: path_params do
      assert_empty parsed_body
    end
  end

  test "GET requests is open to a squadron officer without a fleet privilege" do
    officer = @fleet.fleet_squadron_roles.find_by!(key: "officer")
    create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by(user: @member), fleet_squadron_role: officer)
    sign_in @member

    assert_api_response :get, 200, path_params: path_params
  end

  test "GET requests is refused to an ordinary member" do
    sign_in @member

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET requests needs a session" do
    assert_api_response :get, 401, path_params: path_params
  end
end
