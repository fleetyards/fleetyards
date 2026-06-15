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
        schema "$ref": "#/components/schemas/StandardError"
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
end
