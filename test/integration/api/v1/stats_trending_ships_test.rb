# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsTrendingShipsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/trending-ships" do
    get("Stats Trending Ships") do
      operationId "trendingShips"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/trending-ships returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/trending-ships names the ship a slug belongs to" do
    model = create(:model)
    record_views(model.slug, 12)

    assert_api_response :get, 200 do
      assert_equal [model.name], parsed_body.map { |point| point["label"] }
      assert_equal [12], parsed_body.map { |point| point["count"] }
    end
  end

  # `/ships/viewer/` and `/ships/fleetchart/` are routes, so the rollup collects
  # them alongside the real slugs and the endpoint has to drop them.
  test "GET /stats/trending-ships drops a slug that is not a ship" do
    record_views("viewer", 99)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/trending-ships drops a ship that is no longer visible" do
    hidden = create(:model, hidden: true)
    record_views(hidden.slug, 40)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/trending-ships ignores views older than the window" do
    model = create(:model)
    record_views(model.slug, 5, at: 2.days.ago)
    record_views(model.slug, 7, at: 90.days.ago)

    assert_api_response :get, 200 do
      assert_equal [5], parsed_body.map { |point| point["count"] }
    end
  end

  private def record_views(slug, views, at: 1.day.ago)
    Rollup.create!(
      name: MetricsJob::ROLLUP_SHIP_VIEWS,
      interval: "day",
      time: at.beginning_of_day,
      value: views,
      dimensions: {model_slug: slug}
    )
  end
end
