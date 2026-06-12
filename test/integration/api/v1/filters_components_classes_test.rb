# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FiltersComponentsClassesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/classes" do
    get("Components Classes Filters") do
      operationId "componentClassesFilters"
      tags "ComponentsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  test "GET /filters/components/classes returns component class filter options" do
    create_list(:component, 2)

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
