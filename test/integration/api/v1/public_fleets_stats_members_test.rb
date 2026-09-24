# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsStatsMembersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/stats/members" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Members Stats") do
      operationId "publicFleetMembersStats"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/FleetMembersStatsPublic"
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /public/fleets/:fleetSlug/stats/members returns stats for a public fleet" do
    member = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/members returns 404 for non-public stats" do
    fleet = create(:fleet, public_fleet_stats: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/members returns 404 for unknown slug" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /public/fleets/:fleetSlug/stats/members counts a member in two named squadrons once" do
    Flipper.enable("fleet_squadrons")
    member = create(:user)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])
    squadron = create(:fleet_squadron, fleet: fleet)
    team = create(:fleet_squadron, fleet: fleet, team: true)
    membership = fleet.fleet_memberships.find_by!(user: member)
    [squadron, team].each { |group| create(:fleet_squadron_membership, fleet_squadron: group, fleet_membership: membership) }

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {squadronSlugIn: [squadron.slug, team.slug]}} do
      assert_equal 1, parsed_body["total"]
    end
  end
end
