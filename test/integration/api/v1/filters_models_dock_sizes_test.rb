# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FiltersModelsDockSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/dock-sizes" do
    get("Model Dock Sizes Filters") do
      operationId "modelDockSizesFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/models/dock-sizes returns filter options" do
    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
