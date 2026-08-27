# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersEquipmentItemTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/equipment/item-types" do
    get("Equipment Item Type Filters") do
      operationId "equipmentItemTypesFilters"
      tags "EquipmentFilters"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::EquipmentItemTypeFilterQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:equipment, item_type: "assault_rifle")
    create(:equipment, item_type: "assault_rifle")
    create(:equipment, :attachment, item_type: "weapon_scope")
  end

  test "GET /filters/equipment/item-types returns one option per type" do
    assert_api_response :get, 200 do
      assert_equal %w[assault_rifle weapon_scope], parsed_body.map { |filter| filter["value"] }
      assert_equal "item_type", parsed_body.first["category"]
    end
  end

  test "GET /filters/equipment/item-types skips hidden variants" do
    create(:equipment, :hidden, item_type: "toy_pistol")

    assert_api_response :get, 200 do
      assert_equal %w[assault_rifle weapon_scope], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/equipment/item-types narrows to the equipment types asked for" do
    assert_api_response :get, 200, params: {q: {equipmentTypeIn: ["weapon"]}} do
      assert_equal %w[assault_rifle], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/equipment/item-types ignores an equipment type the game does not have" do
    assert_api_response :get, 200, params: {q: {equipmentTypeIn: ["nonsense"]}} do
      assert_equal %w[assault_rifle weapon_scope], parsed_body.map { |filter| filter["value"] }
    end
  end

  test "GET /filters/equipment/item-types humanises a type with no translation" do
    create(:equipment, item_type: "newfangled_blaster")

    assert_api_response :get, 200 do
      option = parsed_body.find { |filter| filter["value"] == "newfangled_blaster" }

      assert_equal "Newfangled blaster", option["label"]
    end
  end
end
