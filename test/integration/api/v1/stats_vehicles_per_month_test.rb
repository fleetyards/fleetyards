# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsVehiclesPerMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/vehicles-per-month" do
    get("Stats Vehicles per Month") do
      operationId "vehiclesPerMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}
      end
    end
  end

  test "GET /stats/vehicles-per-month returns chart data" do
    assert_api_response :get, 200
  end
end
