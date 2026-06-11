# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::StatsMostViewedPagesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/stats/most-viewed-pages" do
    get("Stats most viewed Pages") do
      operationId "mostViewedPages"
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

  test "GET /stats/most-viewed-pages returns chart data for admin" do
    user = create(:admin_user, resource_access: [:stats])
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /stats/most-viewed-pages returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
