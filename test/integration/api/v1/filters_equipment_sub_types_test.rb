# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentSubTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/sub-types" do
    get("Equipment Sub Type Filters") do
      operationId "equipmentSubTypesFilters"
      tags "EquipmentFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:equipment, sub_type: "Medium")
    create(:equipment, sub_type: "Medium")
    create(:equipment, :attachment, sub_type: "IronSight")
  end

  test "GET /filters/equipment/sub-types returns one option per sub-type" do
    assert_api_response :get, 200 do
      assert_equal %w[IronSight Medium], parsed_body.map { |filter| filter["value"] }
      assert_equal "sub_type", parsed_body.first["category"]
    end
  end
end
