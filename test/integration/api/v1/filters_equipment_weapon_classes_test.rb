# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentWeaponClassesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/weapon-classes" do
    get("Equipment Weapon Class Filters") do
      operationId "equipmentWeaponClassesFilters"
      tags "EquipmentFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:equipment, weapon_class: "ballistic")
    create(:equipment, weapon_class: "energy")
  end

  test "GET /filters/equipment/weapon-classes returns the classes the catalogue carries" do
    assert_api_response :get, 200 do
      assert_equal %w[ballistic energy], parsed_body.map { |filter| filter["value"] }
      assert_equal "weapon_class", parsed_body.first["category"]
    end
  end
end
