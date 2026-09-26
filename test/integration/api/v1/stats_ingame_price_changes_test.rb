# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsIngamePriceChangesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/ingame-price-changes" do
    get("Stats Ingame Price Changes") do
      operationId "ingamePriceChanges"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  setup do
    Rails.cache.clear
  end

  private def snapshot(model, price, days_ago:, location: "Area18", price_type: "sell")
    ItemPriceSnapshot.create!(
      item: model,
      location:,
      price:,
      price_type:,
      recorded_on: days_ago.days.ago.to_date
    )
  end

  test "GET /stats/ingame-price-changes returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/ingame-price-changes reports the percent move between the first and last day" do
    model = create(:model)
    snapshot(model, 1_000_000, days_ago: 20)
    snapshot(model, 1_100_000, days_ago: 10)
    snapshot(model, 1_250_000, days_ago: 1)

    assert_api_response :get, 200 do
      assert_equal [model.name], parsed_body.map { |point| point["label"] }
      assert_equal [25], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /stats/ingame-price-changes ranks a cut beside a rise" do
    cut = create(:model)
    rise = create(:model)
    snapshot(cut, 1000, days_ago: 5)
    snapshot(cut, 400, days_ago: 1)
    snapshot(rise, 1000, days_ago: 5)
    snapshot(rise, 1100, days_ago: 1)

    assert_api_response :get, 200 do
      assert_equal [cut.name, rise.name], parsed_body.map { |point| point["label"] }
      assert_equal [-60, 10], parsed_body.map { |point| point["count"] }
    end
  end

  # The cheapest terminal leaving reads as a rise on `models.price`, though no
  # shop charged a credit more.
  test "GET /stats/ingame-price-changes ignores a terminal that stopped listing the ship" do
    model = create(:model)
    snapshot(model, 800, days_ago: 5, location: "Lorville")
    snapshot(model, 1000, days_ago: 5, location: "Area18")
    snapshot(model, 1000, days_ago: 1, location: "Area18")

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/ingame-price-changes compares the median of the shared terminals" do
    model = create(:model)
    snapshot(model, 1000, days_ago: 5, location: "Area18")
    snapshot(model, 1000, days_ago: 5, location: "Lorville")
    snapshot(model, 1000, days_ago: 5, location: "New Babbage")
    snapshot(model, 1000, days_ago: 1, location: "Area18")
    snapshot(model, 1200, days_ago: 1, location: "Lorville")
    snapshot(model, 9000, days_ago: 1, location: "New Babbage")

    assert_api_response :get, 200 do
      assert_equal [20], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /stats/ingame-price-changes leaves out rental prices" do
    model = create(:model)
    snapshot(model, 1000, days_ago: 5, price_type: "rental")
    snapshot(model, 2000, days_ago: 1, price_type: "rental")

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/ingame-price-changes ignores days older than the window" do
    model = create(:model)
    snapshot(model, 1000, days_ago: 60)
    snapshot(model, 2000, days_ago: 1)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/ingame-price-changes drops a ship that is no longer visible" do
    model = create(:model, hidden: true)
    snapshot(model, 1000, days_ago: 5)
    snapshot(model, 2000, days_ago: 1)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end
end
