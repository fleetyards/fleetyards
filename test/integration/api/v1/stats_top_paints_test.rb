# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsTopPaintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/top-paints" do
    get("Stats Top Paints") do
      operationId "topPaints"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/top-paints returns chart data" do
    assert_api_response :get, 200
  end

  # Paint names repeat across ships, so the ship has to be part of the label or
  # two unrelated paints merge into one bar.
  test "GET /stats/top-paints names the ship the paint belongs to" do
    model = create(:model, name: "Corsair")
    paint = create(:model_paint, model:, name: "Best in Show")
    create_list(:vehicle, 2, model:, model_paint: paint, wanted: false, loaner: false)

    assert_api_response :get, 200 do
      assert_equal ["Corsair - Best in Show"], parsed_body.map { |point| point["label"] }
      assert_equal [2], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /stats/top-paints ignores a ship with no paint set" do
    model = create(:model)
    create(:vehicle, model:, model_paint: nil, wanted: false, loaner: false)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/top-paints leaves out wishlist entries and loaners" do
    model = create(:model)
    paint = create(:model_paint, model:)
    create(:vehicle, model:, model_paint: paint, wanted: true, loaner: false)
    create(:vehicle, model:, model_paint: paint, wanted: false, loaner: true)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end
end
