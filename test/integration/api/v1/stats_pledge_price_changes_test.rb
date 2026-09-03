# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsPledgePriceChangesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/pledge-price-changes" do
    get("Stats Pledge Price Changes") do
      operationId "pledgePriceChanges"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/pledge-price-changes returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/pledge-price-changes reports the net move over the window" do
    model = create(:model, pledge_price: 100)
    model.update!(pledge_price: 150)
    model.update!(pledge_price: 250)

    assert_api_response :get, 200 do
      assert_equal [model.name], parsed_body.map { |point| point["label"] }
      assert_equal [150], parsed_body.map { |point| point["count"] }
    end
  end

  # 161 of the recorded moves are cuts, so ranking by value rather than by size
  # would push the steepest of them off the end of a chart about movement.
  test "GET /stats/pledge-price-changes ranks a cut beside a rise" do
    cut = create(:model, pledge_price: 1000)
    rise = create(:model, pledge_price: 100)
    cut.update!(pledge_price: 100)
    rise.update!(pledge_price: 200)

    assert_api_response :get, 200 do
      assert_equal [cut.name, rise.name], parsed_body.map { |point| point["label"] }
      assert_equal [-900, 100], parsed_body.map { |point| point["count"] }
    end
  end

  # 189 of the 692 recorded changes are a ship first getting a price. Counting
  # those as a rise from zero would put every new ship at the top.
  test "GET /stats/pledge-price-changes leaves out a ship that was first priced" do
    model = create(:model, pledge_price: nil)
    model.update!(pledge_price: 400)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/pledge-price-changes leaves out a price that was taken away" do
    model = create(:model, pledge_price: 400)
    model.update!(pledge_price: nil)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/pledge-price-changes ignores changes older than the window" do
    model = create(:model, pledge_price: 100)
    travel_to(2.years.ago) { model.update!(pledge_price: 900) }

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/pledge-price-changes drops a ship that is no longer visible" do
    model = create(:model, pledge_price: 100, hidden: true)
    model.update!(pledge_price: 500)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end
end
