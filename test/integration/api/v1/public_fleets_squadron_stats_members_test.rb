# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsSquadronStatsMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/squadrons/{fleetSquadronSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetSquadronSlug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Public Fleet Squadron Members Stats") do
      operationId "publicFleetSquadronMembersStats"
      tags "FleetSquadrons"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMembersStatsPublic
      end

      response(404, "not found unless the fleet publishes its stats") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @member = create(:user)
    @fleet = create(:fleet, :with_public_stats, admins: [create(:user)], members: [@member])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership)
  end

  test "a squadron's size is readable when the fleet publishes its stats" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: @squadron.slug} do
      assert_equal 1, parsed_body["total"]
    end
  end

  test "a public fleet that has not published its stats hands over no squadron numbers" do
    quiet = create(:fleet, admins: [create(:user)])
    squadron = create(:fleet_squadron, fleet: quiet)

    assert_api_response :get, 404,
      path_params: {fleetSlug: quiet.slug, fleetSquadronSlug: squadron.slug}
  end

  test "an unknown squadron is not found" do
    assert_api_response :get, 404,
      path_params: {fleetSlug: @fleet.slug, fleetSquadronSlug: "no-such-wing"}
  end
end
