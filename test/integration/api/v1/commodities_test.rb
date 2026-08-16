# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CommoditiesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/commodities" do
    get("Commodities list") do
      operationId "commodities"
      tags "Commodities"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Commodity.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CommodityQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodities"
      end
    end
  end

  setup do
    @gold = create(:commodity, name: "Gold", commodity_type: "metal")
    @laranite = create(:commodity, name: "Laranite", commodity_type: "mineral")
    @waste = create(:commodity, name: "Waste", commodity_type: "waste")
  end

  test "GET /commodities lists all commodities sorted by name" do
    assert_api_response :get, 200 do
      assert_equal %w[Gold Laranite Waste], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by nameCont" do
    assert_api_response :get, 200, params: {q: {"nameCont" => "aran"}} do
      assert_equal ["Laranite"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by commodityTypeIn" do
    assert_api_response :get, 200, params: {q: {"commodityTypeIn" => %w[metal mineral]}} do
      assert_equal %w[Gold Laranite], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /commodities exposes the fields the picker needs" do
    assert_api_response :get, 200 do
      gold = parsed_body["items"].find { |item| item["name"] == "Gold" }

      assert_equal @gold.id, gold["id"]
      assert_equal "gold", gold["slug"]
      assert_equal "metal", gold["commodityType"]
    end
  end
end
