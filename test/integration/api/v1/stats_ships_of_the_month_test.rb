# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsShipsOfTheMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/ships-of-the-month" do
    get("Stats Ships of the Month") do
      operationId "shipsOfTheMonth"
      tags "Stats"
      produces "application/json"

      parameter name: "months", in: :query, required: false, schema: {
        type: :integer,
        minimum: 1,
        maximum: ::Api::V1::Stats::BaseController::SHIPS_OF_THE_MONTH_MAX
      }, description: "How many months back to reach"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end

      response(400, "invalid range") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end
  end

  test "GET /stats/ships-of-the-month returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/ships-of-the-month shows a year by default" do
    record("Carrack", at: 2.months.ago)
    record("Prospector", at: 18.months.ago)

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
    end
  end

  # The rollup goes back as far as it was ever written; the chart asked for a
  # year because that is all it ever showed, not because that is all there is.
  test "GET /stats/ships-of-the-month reaches further back on request" do
    record("Carrack", at: 2.months.ago)
    record("Prospector", at: 18.months.ago)

    assert_api_response :get, 200, params: {months: 24} do
      assert_equal 2, parsed_body.count
    end
  end

  # The parameter reaches a `months.ago`, so an unbounded one would ask for
  # every rollup ever written. The declared maximum turns that away before the
  # controller sees it, rather than quietly returning something else than asked.
  test "GET /stats/ships-of-the-month refuses a range beyond the maximum" do
    record("Carrack", at: 2.months.ago)

    assert_api_response :get, 400, params: {months: 99_999}
  end

  private def record(name, at:)
    Rollup.create!(
      name: MetricsJob::ROLLUP_SHIP_OF_THE_PERIOD,
      interval: "month",
      time: at.beginning_of_month,
      value: 5,
      dimensions: {name: name}
    )
  end
end
