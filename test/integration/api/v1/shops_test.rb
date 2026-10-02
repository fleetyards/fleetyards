# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ShopsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/shops/{slug}" do
    get("Shop Detail") do
      operationId "shop"
      tags "Shops"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::Shop
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @system = create(:location, name: "Stanton System", kind: "system")
    @star = create(:location, name: "Stanton", kind: "star", parent: @system, system: @system)
    @hurston = create(:location, name: "Hurston", kind: "planet", parent: @star, system: @system)
    @everus = create(:location, name: "Everus Harbor", kind: "station", parent: @hurston, system: @system)
    @casaba = Shop.create!(name: "Casaba Outlet", location: @everus)

    jacket = create(:equipment, name: "Adiva Jacket")
    create(:item_price, item: jacket, location: "Casaba Outlet - Everus Harbor", price: 210, price_type: "sell", time_range: nil, shop: @casaba)
  end

  test "GET /shops/{slug} returns the shop, its place and what it sells" do
    assert_api_response :get, 200, params: {slug: @casaba.slug} do
      assert_equal "Casaba Outlet", parsed_body["name"]
      assert_equal "Everus Harbor", parsed_body.dig("location", "name")
      assert_equal ["Stanton System", "Hurston", "Everus Harbor"], parsed_body["ancestors"].pluck("name")
      assert_equal [["Adiva Jacket", "Equipment"]], parsed_body["items"].map { |item| item.values_at("name", "itemType") }
      assert_equal 210.0, parsed_body.dig("items", 0, "prices", 0, "price")
    end
  end

  test "GET /shops/{slug} answers 404 for an unknown shop" do
    assert_api_response :get, 404, params: {slug: "dumpers-depot-port-olisar"}
  end
end
