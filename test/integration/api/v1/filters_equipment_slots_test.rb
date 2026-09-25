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
end
