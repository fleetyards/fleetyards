# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/quick-stats" do
    get("Stats") do
      operationId "stats"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stats"
      end
    end
  end

  test "GET /stats/quick-stats returns the quick stats" do
    assert_api_response :get, 200
  end
end
