# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsFocusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/focus" do
    get("Model focus Filters") do
      operationId "modelFocusFilters"
      tags "ModelsFilters"
      produces "application/json"

      parameter name: :classification, in: :query, schema: {type: :string}, required: false,
        description: "Restrict the result to focuses of models with this classification"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  setup do
    create_list(:model, 2)
  end

  test "GET /filters/models/focus returns filter options" do
    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /filters/models/focus filters by classification" do
    create(:model, classification: "combat", focus: "Heavy Fighter")
    create(:model, classification: "industrial", focus: "Mining")

    assert_api_response :get, 200, params: {classification: "combat"} do
      refute_includes parsed_body.map { |row| row["value"] }, "Mining"
    end
  end
end
