# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CommoditiesPriceHistoryTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/commodities/{slug}/price-history" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Commodity slug", required: true

    get("Commodity Price History") do
      operationId "commodityPriceHistory"
      tags "Commodities"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Commodities::CommodityPricePointsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /commodities/:slug/price-history spans the terminals of each day" do
    commodity = create(:commodity)
    record(commodity, price: 100, price_type: "sell", location: "Area 18")
    record(commodity, price: 140, price_type: "sell", location: "Lorville")

    assert_api_response :get, 200, path_params: {slug: commodity.slug} do
      day = parsed_body.sole

      assert_equal 100, day["soldLowest"].to_i
      assert_equal 120, day["soldAverage"].to_i
      assert_equal 140, day["soldHighest"].to_i
    end
  end

  # `sell` is the shop selling and `bought` the shop buying, the perspective the
  # commodity's own `soldAt` and `boughtAt` already use.
  test "GET /commodities/:slug/price-history keeps the two directions apart" do
    commodity = create(:commodity)
    record(commodity, price: 100, price_type: "sell", location: "Area 18")
    record(commodity, price: 80, price_type: "buy", location: "Area 18")

    assert_api_response :get, 200, path_params: {slug: commodity.slug} do
      day = parsed_body.sole

      assert_equal 100, day["soldAverage"].to_i
      assert_equal 80, day["boughtAverage"].to_i
    end
  end

  test "GET /commodities/:slug/price-history returns the days oldest first" do
    commodity = create(:commodity)
    record(commodity, price: 10, recorded_on: 3.days.ago.to_date)
    record(commodity, price: 20, recorded_on: 1.day.ago.to_date)

    assert_api_response :get, 200, path_params: {slug: commodity.slug} do
      assert_equal [10, 20], parsed_body.map { |day| day["soldAverage"].to_i }
    end
  end

  test "GET /commodities/:slug/price-history leaves out days beyond the window" do
    commodity = create(:commodity)
    record(commodity, price: 10, recorded_on: 200.days.ago.to_date)

    assert_api_response :get, 200, path_params: {slug: commodity.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /commodities/:slug/price-history answers for a commodity nothing has priced" do
    commodity = create(:commodity)

    assert_api_response :get, 200, path_params: {slug: commodity.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /commodities/:slug/price-history returns 404 for an unknown commodity" do
    assert_api_response :get, 404, path_params: {slug: "unknown-commodity"}
  end

  private def record(commodity, price:, price_type: "sell", location: "Area 18", recorded_on: Date.current)
    ItemPriceSnapshot.create!(
      item: commodity, location:, price_type:, price:, recorded_on:
    )
  end
end
