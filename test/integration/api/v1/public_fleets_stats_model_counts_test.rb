# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicFleetsStatsModelCountsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/stats/model-counts" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Stats Model Counts") do
      operationId "publicFleetStatsModelCounts"
      tags "Fleets"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"
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

  test "GET /public/fleets/:fleetSlug/stats/model-counts returns counts" do
    member = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      expected = member.vehicles.each_with_object({}) { |v, h| h[v.model.slug] = 1 }
      assert_equal expected, parsed_body["modelCounts"]
    end
  end

  test "GET /public/fleets/:fleetSlug/stats/model-counts filters by modelNameCont" do
    member = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])
    target = member.vehicles.first

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {"modelNameCont" => target.model.name}} do
      assert_equal({target.model.slug => 1}, parsed_body["modelCounts"])
    end
  end

  test "GET /public/fleets/:fleetSlug/stats/model-counts returns 404 for non-public stats" do
    fleet = create(:fleet, public_fleet_stats: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/model-counts returns 404 for unknown fleet" do
    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end
end
