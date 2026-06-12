# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicFleetsStatsModelsByManufacturerTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{fleetSlug}/stats/models-by-manufacturer" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Public Fleet Models by Manufacturer") do
      operationId "publicFleetModelsByManufacturer"
      tags "FleetStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
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

  test "GET /public/fleets/:fleetSlug/stats/models-by-manufacturer returns chart data" do
    member = create(:user, vehicle_count: 3)
    fleet = create(:fleet, public_fleet_stats: true, members: [member])

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug}
  end

  test "GET /public/fleets/:fleetSlug/stats/models-by-manufacturer returns 404 for non-public stats" do
    fleet = create(:fleet, public_fleet_stats: false)

    assert_api_response :get, 404, path_params: {fleetSlug: fleet.slug}
  end
end
