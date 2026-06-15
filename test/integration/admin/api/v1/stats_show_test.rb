# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::StatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/stats/quick-stats" do
    get("Stats") do
      operationId "stats"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Stats"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /stats/quick-stats returns aggregated stats for admin" do
    user = create(:admin_user, resource_access: [:stats])
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /stats/quick-stats returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
