# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsVehiclesByModelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/vehicles-by-model" do
    get("Stats Vehicles by Model") do
      operationId "vehiclesByModel"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/vehicles-by-model returns chart data" do
    assert_api_response :get, 200
  end
end
