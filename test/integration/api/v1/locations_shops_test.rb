# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsShopsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}/shops" do
    get("Location shops") do
      operationId "locationShops"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::LocationShops
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @everus = create(:location, name: "Everus Harbor", kind: "station")
    @jacket = create(:equipment, name: "Adiva Jacket")
    @helmet = create(:equipment, name: "Arden-SL Helmet")

    # Linked after the fact: FactoryBot reads a `location_id` override as the
    # `location` string's and drops that.
    [@jacket, @helmet].each do |item|
      create(:item_price, item:, location: "Casaba Outlet - Everus Harbor", price_type: "sell", time_range: nil)
        .update_columns(location_id: @everus.id, shop_name: "Casaba Outlet")
    end
    create(:item_price, item: @jacket, location: "Casaba Outlet - Area 18", price_type: "sell", time_range: nil)
  end

  test "GET /locations/{slug}/shops lists each shop at the place with what it sells" do
    assert_api_response :get, 200, params: {slug: @everus.slug} do
      shop = parsed_body["shops"].sole

      assert_equal ["Casaba Outlet", 2], shop.values_at("name", "itemsCount")
      assert_equal ["Adiva Jacket", "Arden-SL Helmet"], shop["items"].pluck("name")
      assert_equal %w[Equipment], shop["items"].pluck("itemType").uniq
      assert_equal "sell", shop.dig("items", 0, "prices", 0, "priceType")
    end
  end

  test "GET /locations/{slug}/shops answers 404 for an unknown place" do
    assert_api_response :get, 404, params: {slug: "port-olisar"}
  end
end
