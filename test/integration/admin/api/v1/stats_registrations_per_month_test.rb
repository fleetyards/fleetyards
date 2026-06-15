# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::StatsRegistrationsPerMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/stats/registrations-per-month" do
    get("Stats Registrations per Month") do
      operationId "registrationsPerMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /stats/registrations-per-month returns chart data for admin" do
    user = create(:admin_user, resource_access: [:stats])
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /stats/registrations-per-month returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
