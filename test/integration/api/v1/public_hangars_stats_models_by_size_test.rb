# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicHangarsStatsModelsBySizeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/stats/models-by-size" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "username"

    get("Public Hangar Models by Size") do
      operationId "publicHangarModelsBySize"
      tags "PublicHangarStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /public/hangars/:username/stats/models-by-size returns chart data" do
    user = create(:user, public_hangar_stats: true, vehicle_count: 3)

    assert_api_response :get, 200, path_params: {username: user.username}
  end

  test "GET /public/hangars/:username/stats/models-by-size returns 404 for non-public stats" do
    user = create(:user, public_hangar_stats: false)

    assert_api_response :get, 404, path_params: {username: user.username}
  end
end
