# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsModelsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models" do
    get("Models Filters") do
      operationId "modelFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/models returns filter options" do
    create_list(:model, 2)

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
