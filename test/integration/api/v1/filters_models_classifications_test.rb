# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FiltersModelsClassificationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/classifications" do
    get("Model classifications Filters") do
      operationId "modelClassificationsFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/models/classifications returns filter options" do
    create_list(:model, 2)

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
