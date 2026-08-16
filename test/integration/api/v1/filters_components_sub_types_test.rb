# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersComponentsSubTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/sub-types" do
    get("Components Sub Type Filters") do
      operationId "componentSubTypesFilters"
      tags "ComponentsFilters"
      produces "application/json"

      parameter name: "category", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}
      end
    end
  end

  setup do
    @version = Rails.configuration.sc_data[:version]

    create(:component, category: "weapons", component_sub_type: "Gun", version: @version)
    create(:component, category: "weapons", component_sub_type: "Missile", version: @version)
    create(:component, category: "turret", component_sub_type: "MannedTurret", version: @version)
  end

  test "GET /filters/components/sub-types returns every sub type" do
    assert_api_response :get, 200 do
      assert_equal %w[Gun MannedTurret Missile], parsed_body.map { |filter| filter["value"] }
      assert_equal "sub_type", parsed_body.first["category"]
    end
  end

  test "GET /filters/components/sub-types narrows down to a category" do
    assert_api_response :get, 200, params: {category: "weapons"} do
      assert_equal %w[Gun Missile], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/components/sub-types humanizes labels" do
    assert_api_response :get, 200, params: {category: "turret"} do
      assert_equal "Manned Turret", parsed_body.first["label"]
    end
  end

  test "GET /filters/components/sub-types excludes older game versions" do
    create(:component, category: "weapons", component_sub_type: "Torpedo", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {category: "weapons"} do
      assert_equal %w[Gun Missile], parsed_body.map { |filter| filter["value"] }
    end
  end
end
