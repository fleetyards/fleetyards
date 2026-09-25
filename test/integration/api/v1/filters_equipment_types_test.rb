# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/types" do
    get("Equipment Type Filters") do
      operationId "equipmentTypesFilters"
      tags "EquipmentFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:equipment)
    create(:equipment, :armor)
    create(:equipment, :hidden, equipment_type: "medical")
  end

  test "GET /filters/equipment/types offers the types the catalogue carries" do
    assert_api_response :get, 200 do
      assert_equal %w[armor weapon], parsed_body.map { |filter| filter["value"] }
      assert_equal "equipment_type", parsed_body.first["category"]
    end
  end
end
