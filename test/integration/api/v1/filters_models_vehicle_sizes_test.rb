# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsVehicleSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/vehicle-sizes" do
    get("Model Vehicle Sizes Filters") do
      operationId "modelVehicleSizesFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  test "GET /filters/models/vehicle-sizes returns the ladder smallest first" do
    assert_api_response :get, 200 do
      values = parsed_body.map { |filter| filter["value"] }

      assert_equal Model::VEHICLE_SIZES, values
    end
  end
end
