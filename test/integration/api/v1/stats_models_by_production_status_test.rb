# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::StatsModelsByProductionStatusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/models-by-production-status" do
    get("Stats Models by Production-Status") do
      operationId "modelsByProductionStatus"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
      end
    end
  end

  test "GET /stats/models-by-production-status returns chart data" do
    assert_api_response :get, 200
  end
end
