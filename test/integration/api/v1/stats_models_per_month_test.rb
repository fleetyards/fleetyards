# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsModelsPerMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/models-per-month" do
    get("Stats Models per Month") do
      operationId "modelsPerMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}
      end
    end
  end

  test "GET /stats/models-per-month returns chart data" do
    assert_api_response :get, 200
  end
end
