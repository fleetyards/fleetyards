# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FiltersVehiclesBoughtViaTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/vehicles/bought-via" do
    get("Vehicles Bought Via Filters") do
      operationId "vehicleBoughtViaFilters"
      tags "VehicleFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/vehicles/bought-via returns filter options" do
    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
