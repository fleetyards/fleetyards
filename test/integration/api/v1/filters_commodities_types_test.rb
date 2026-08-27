# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersCommoditiesTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/commodities/types" do
    get("Commodity Types Filters") do
      operationId "commodityTypesFilters"
      tags "CommoditiesFilters"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FilterOptionsList"
      end
    end
  end

  setup do
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "metal")
    create(:commodity, commodity_type: "consumer_goods")
  end

  test "GET /filters/commodities/types returns one option per type" do
    assert_api_response :get, 200 do
      assert_equal %w[consumer_goods metal], parsed_body.map { |filter| filter["value"] }
      assert_equal "commodity_type", parsed_body.first["category"]
    end
  end

  test "GET /filters/commodities/types falls back to the raw value without a translation" do
    create(:commodity, commodity_type: "newfangledgoo")

    assert_api_response :get, 200 do
      option = parsed_body.find { |filter| filter["value"] == "newfangledgoo" }

      assert_equal "Newfangledgoo", option["label"]
    end
  end

  test "GET /filters/commodities/types skips commodities without a type" do
    create(:commodity, commodity_type: nil)

    assert_api_response :get, 200 do
      assert_equal %w[consumer_goods metal], parsed_body.map { |filter| filter["value"] }
    end
  end
end
