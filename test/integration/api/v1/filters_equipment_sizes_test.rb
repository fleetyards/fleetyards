# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/sizes" do
    get("Equipment Size Filters") do
      operationId "equipmentSizesFilters"
      tags "EquipmentFilters"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::EquipmentFacetFilterQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:equipment, size: "3")
    create(:equipment, size: "1")
    create(:equipment, :attachment, size: "1")
    create(:equipment, :hidden, size: "9")
  end

  test "GET /filters/equipment/sizes offers each size a visible item has" do
    assert_api_response :get, 200 do
      assert_equal %w[1 3], parsed_body.map { |filter| filter["value"] }
      assert_equal "size", parsed_body.first["category"]
      assert_equal "Size 1", parsed_body.first["label"]
    end
  end

  test "GET /filters/equipment/sizes narrows to the equipment types asked for" do
    assert_api_response :get, 200, params: {q: {equipmentTypeIn: ["weapon_attachment"]}} do
      assert_equal %w[1], parsed_body.map { |filter| filter["value"] }
    end
  end
end
