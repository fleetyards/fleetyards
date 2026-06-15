# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsComponentsByClassTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/components-by-class" do
    get("Stats Components by Class") do
      operationId "componentsByClass"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}
      end
    end
  end

  test "GET /stats/components-by-class returns chart data" do
    assert_api_response :get, 200
  end
end
