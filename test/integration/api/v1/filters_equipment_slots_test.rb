# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentSlotsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/slots" do
    get("Equipment Slot Filters") do
      operationId "equipmentSlotsFilters"
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

  test "GET /filters/equipment/slots offers every slot" do
    assert_api_response :get, 200 do
      assert_equal Equipment.slots.keys, parsed_body.map { |filter| filter["value"] }
      assert_equal "slot", parsed_body.first["category"]
    end
  end

  test "GET /filters/equipment/slots offers only the slots the equipment types asked for fill" do
    create(:equipment, :armor, slot: "helmet")
    create(:equipment, :armor, slot: "legs")
    create(:equipment, :armor, :hidden, slot: "arms")
    create(:equipment, equipment_type: "clothing", item_type: "shirt", slot: "shirt")

    assert_api_response :get, 200, params: {q: {equipmentTypeIn: ["armor"]}} do
      assert_equal %w[helmet legs], parsed_body.map { |filter| filter["value"] }
    end
  end
end
