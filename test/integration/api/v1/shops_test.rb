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

  api_path "/shops/{slug}/items" do
    get("Shop Items") do
      operationId "shopItems"
      tags "Shops"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true
      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Shop.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ShopItemQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::ShopItems
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

    jacket = create(:equipment, name: "Adiva Jacket", equipment_type: "clothing")
    create(:item_price, item: jacket, location: "Casaba Outlet - Everus Harbor", price: 210, price_type: "sell", time_range: nil, shop: @casaba)
  end

  test "GET /shops/{slug} returns the shop, its place and what kinds of thing it sells" do
    assert_api_response :get, 200, api_path: "/shops/{slug}", params: {slug: @casaba.slug} do
      assert_equal "Casaba Outlet", parsed_body["name"]
      assert_equal "Everus Harbor", parsed_body.dig("location", "name")
      assert_equal ["Stanton System", "Hurston", "Everus Harbor"], parsed_body["ancestors"].pluck("name")
      assert_equal 1, parsed_body["itemsCount"]
      assert_equal [["Equipment.clothing", "clothing", "Clothing", 1]], parsed_body["categories"].map { |category| category.values_at("id", "key", "label", "count") }
    end
  end

  test "GET /shops/{slug} answers 404 for an unknown shop" do
    assert_api_response :get, 404, api_path: "/shops/{slug}", params: {slug: "dumpers-depot-port-olisar"}
  end

  test "GET /shops/{slug}/items lists everything it sells in one list, cheapest first on request" do
    model = create(:model, name: "Cutlass Black")
    create(:item_price, item: model, location: "Casaba Outlet - Everus Harbor", price: 9_000, price_type: "rental", time_range: "1-day", shop: @casaba)
    hat = create(:equipment, name: "Beacon Hat", equipment_type: "clothing")
    create(:item_price, item: hat, location: "Casaba Outlet - Everus Harbor", price: 40, price_type: "sell", time_range: nil, shop: @casaba)

    assert_api_response :get, 200, api_path: "/shops/{slug}/items", params: {slug: @casaba.slug, q: {s: "price asc"}} do
      assert_equal ["Beacon Hat", "Adiva Jacket", "Cutlass Black"], parsed_body["items"].pluck("name")
      assert_equal [40.0, 210.0, nil], parsed_body["items"].pluck("buyPrice")
      assert_equal 9_000.0, parsed_body["items"].last["rentalPrice"]
      assert_equal 3, parsed_body.dig("meta", "pagination", "totalCount")
    end
  end

  test "GET /shops/{slug}/items narrows to categories and a name" do
    model = create(:model, name: "Cutlass Black")
    create(:item_price, item: model, location: "Casaba Outlet - Everus Harbor", price: 9_000, price_type: "rental", time_range: "1-day", shop: @casaba)

    assert_api_response :get, 200, api_path: "/shops/{slug}/items", params: {slug: @casaba.slug, q: {categoryIn: ["Model"]}} do
      assert_equal [["Cutlass Black", "Model"]], parsed_body["items"].map { |item| item.values_at("name", "categoryId") }
    end

    assert_api_response :get, 200, api_path: "/shops/{slug}/items", params: {slug: @casaba.slug, q: {categoryNotIn: ["Model"]}} do
      assert_equal ["Adiva Jacket"], parsed_body["items"].pluck("name")
    end

    assert_api_response :get, 200, api_path: "/shops/{slug}/items", params: {slug: @casaba.slug, q: {nameCont: "jack"}} do
      assert_equal ["Adiva Jacket"], parsed_body["items"].pluck("name")
    end
  end

  test "GET /shops/{slug}/items answers 404 for an unknown shop" do
    assert_api_response :get, 404, api_path: "/shops/{slug}/items", params: {slug: "dumpers-depot-port-olisar"}
  end
end
