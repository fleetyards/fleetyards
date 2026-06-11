# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::StatsModelsByManufacturerTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/models-by-manufacturer" do
    get("Stats Models by Manufacturer") do
      operationId "modelsByManufacturer"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
      end
    end
  end

  test "GET /stats/models-by-manufacturer returns chart data" do
    assert_api_response :get, 200
  end
end
