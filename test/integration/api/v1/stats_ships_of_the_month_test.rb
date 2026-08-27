# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsShipsOfTheMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/ships-of-the-month" do
    get("Stats Ships of the Month") do
      operationId "shipsOfTheMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/ships-of-the-month returns chart data" do
    assert_api_response :get, 200
  end
end
