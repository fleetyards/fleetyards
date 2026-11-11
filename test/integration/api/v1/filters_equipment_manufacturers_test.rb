# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentManufacturersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/manufacturers" do
    get("Equipment Manufacturer Filters") do
      operationId "equipmentManufacturersFilters"
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
    @behring = create(:manufacturer, name: "Behring")
    @clark = create(:manufacturer, name: "Clark Defense Systems")
    @hidden_maker = create(:manufacturer, name: "Hidden Works")
    create(:manufacturer, name: "Shipwright")

    create(:equipment, manufacturer: @behring)
    create(:equipment, :armor, manufacturer: @clark)
    create(:equipment, :hidden, manufacturer: @hidden_maker)
  end

  test "GET /filters/equipment/manufacturers offers each maker of a visible item" do
    assert_api_response :get, 200 do
      assert_equal [@behring.slug, @clark.slug], parsed_body.map { |filter| filter["value"] }
      assert_equal "manufacturer", parsed_body.first["category"]
      assert_equal "Behring", parsed_body.first["label"]
    end
  end

  test "GET /filters/equipment/manufacturers narrows to the slot asked for" do
    assert_api_response :get, 200, params: {q: {equipmentTypeIn: ["armor"], slotIn: ["torso"]}} do
      assert_equal [@clark.slug], parsed_body.map { |filter| filter["value"] }
    end
  end
end
