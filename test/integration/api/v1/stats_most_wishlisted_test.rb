# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsMostWishlistedTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/most-wishlisted" do
    get("Stats Most Wishlisted") do
      operationId "mostWishlisted"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/most-wishlisted returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/most-wishlisted ranks ships by this month's additions" do
    popular = create(:model)
    quiet = create(:model)
    record_additions(popular, 30)
    record_additions(quiet, 4)

    assert_api_response :get, 200 do
      assert_equal [popular.name, quiet.name], parsed_body.map { |point| point["label"] }
      assert_equal [30, 4], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /stats/most-wishlisted drops a ship that is no longer visible" do
    hidden = create(:model, hidden: true)
    record_additions(hidden, 50)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/most-wishlisted ignores earlier months" do
    model = create(:model)
    record_additions(model, 9, at: 3.months.ago)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  private def record_additions(model, additions, at: Time.current)
    Rollup.create!(
      name: MetricsJob::ROLLUP_WISHLIST_BY_MODEL,
      interval: "month",
      time: at.beginning_of_month,
      value: additions,
      dimensions: {model_id: model.id}
    )
  end
end
