# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersComponentsSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/sizes" do
    get("Components Size Filters") do
      operationId "componentSizesFilters"
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

    create(:component, category: "weapons", size: "10", version: @version)
    create(:component, category: "weapons", size: "2", version: @version)
    create(:component, category: "cooler", size: "1", version: @version)
    create(:component, category: "cooler", size: "2", version: @version)
  end

  test "GET /filters/components/sizes offers each size in numeric order" do
    assert_api_response :get, 200 do
      assert_equal %w[1 2 10], parsed_body.map { |filter| filter["value"] }
      assert_equal "size", parsed_body.first["category"]
      assert_equal "Size 1", parsed_body.first["label"]
    end
  end

  test "GET /filters/components/sizes narrows to the categories asked for" do
    assert_api_response :get, 200, params: {q: {categoryIn: ["weapons"]}} do
      assert_equal %w[2 10], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/components/sizes excludes older game versions" do
    create(:component, category: "weapons", size: "7", version: "0.0.1-live.1")

    assert_api_response :get, 200 do
      assert_equal %w[1 2 10], parsed_body.map { |filter| filter["value"] }
    end
  end
end
