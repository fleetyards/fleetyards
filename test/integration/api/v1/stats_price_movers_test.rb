# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsPriceMoversTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/price-movers" do
    get("Stats Price Movers") do
      operationId "priceMovers"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/price-movers returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/price-movers reports what a week did to the price" do
    commodity = create(:commodity)
    record(commodity, price: 100, recorded_on: 8.days.ago.to_date)
    record(commodity, price: 175, recorded_on: Date.current)

    assert_api_response :get, 200 do
      assert_equal [commodity.name], parsed_body.map { |mover| mover["label"] }
      assert_equal [75], parsed_body.map { |mover| mover["count"] }
    end
  end

  # A drop is as much a mover as a rise, so ranking by value rather than by size
  # of the move would push the steepest fall off the end of the chart.
  test "GET /stats/price-movers ranks a fall beside a rise" do
    faller = create(:commodity)
    riser = create(:commodity)
    record(faller, price: 1000, recorded_on: 8.days.ago.to_date)
    record(faller, price: 100, recorded_on: Date.current)
    record(riser, price: 100, recorded_on: 8.days.ago.to_date)
    record(riser, price: 200, recorded_on: Date.current)

    assert_api_response :get, 200 do
      assert_equal [faller.name, riser.name], parsed_body.map { |mover| mover["label"] }
      assert_equal [-900, 100], parsed_body.map { |mover| mover["count"] }
    end
  end

  test "GET /stats/price-movers leaves out a commodity that did not move" do
    commodity = create(:commodity)
    record(commodity, price: 100, recorded_on: 8.days.ago.to_date)
    record(commodity, price: 100, recorded_on: Date.current)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  # Nothing to compare against until a second week of collecting.
  test "GET /stats/price-movers answers with one day of history" do
    commodity = create(:commodity)
    record(commodity, price: 100, recorded_on: Date.current)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  private def record(commodity, price:, recorded_on:, price_type: "sell", location: "Area 18")
    ItemPriceSnapshot.create!(
      item: commodity, location:, price_type:, price:, recorded_on:
    )
  end
end
