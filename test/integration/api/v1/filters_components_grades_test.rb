# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersComponentsGradesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/grades" do
    get("Components Grade Filters") do
      operationId "componentGradesFilters"
      tags "ComponentsFilters"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ComponentFacetFilterQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    @version = ScData::Source.version

    create(:component, category: "weapons", grade: "3", version: @version)
    create(:component, category: "weapons", grade: "1", version: @version)
    create(:component, category: "cooler", grade: "2", version: @version)
  end

  test "GET /filters/components/grades labels each grade by its letter" do
    assert_api_response :get, 200 do
      assert_equal %w[1 2 3], parsed_body.map { |filter| filter["value"] }
      assert_equal %w[A B C].map { |letter| "Grade #{letter}" }, parsed_body.map { |filter| filter["label"] }
      assert_equal "grade", parsed_body.first["category"]
    end
  end

  test "GET /filters/components/grades narrows to the categories asked for" do
    assert_api_response :get, 200, params: {q: {categoryIn: ["weapons"]}} do
      assert_equal %w[1 3], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/components/grades keeps the raw value for a grade without a letter" do
    create(:component, category: "cooler", grade: "7", version: @version)

    assert_api_response :get, 200, params: {q: {categoryIn: ["cooler"]}} do
      assert_equal ["Grade B", "Grade 7"], parsed_body.map { |filter| filter["label"] }
    end
  end
end
