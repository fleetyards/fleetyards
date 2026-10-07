# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRequestsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/requests" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    post("Request to join a Fleet Squadron") do
      operationId "createFleetSquadronRequest"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronRequest
      end

      response(400, "bad request - a team, already a member, already asked, in another squadron, or waiting on another") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet, name: "Alpha")
    @membership = @fleet.fleet_memberships.kept.find_by(user: @member)
  end

  def path_params(squadron = @squadron)
    {fleetSlug: @fleet.slug, fleetSquadronSlug: squadron.slug}
  end

  test "POST requests asks to join a squadron" do
    sign_in @member

    assert_api_response :post, 201, path_params: path_params do
      assert_equal @member.username, parsed_body.dig("member", "username")
      assert @squadron.fleet_squadron_requests.exists?(fleet_membership: @membership)
    end
  end

  test "POST requests twice is refused" do
    create(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: @membership)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params
  end

  test "POST requests for a team is refused, a team is joined directly" do
    team = create(:fleet_squadron, fleet: @fleet, team: true)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params(team)
  end

  test "POST requests names the squadron the member is already in" do
    other = create(:fleet_squadron, fleet: @fleet, name: "Bravo")
    create(:fleet_squadron_membership, fleet_squadron: other, fleet_membership: @membership)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params do
      assert_includes parsed_body.to_json, "Bravo"
    end
  end

  test "POST requests names the squadron the member is still waiting on" do
    other = create(:fleet_squadron, fleet: @fleet, name: "Bravo")
    create(:fleet_squadron_request, fleet_squadron: other, fleet_membership: @membership)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params do
      assert_includes parsed_body.to_json, "Bravo"
      refute @squadron.fleet_squadron_requests.exists?(fleet_membership: @membership)
    end
  end

  test "POST requests needs a session" do
    assert_api_response :post, 401, path_params: path_params
  end
end
