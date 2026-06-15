# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/sizes" do
    get("Model Sizes Filters") do
      operationId "modelSizesFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/models/sizes returns filter options" do
    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
