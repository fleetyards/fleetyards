# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsWishToOwnRatioTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  FLOOR = ::Api::V1::Stats::BaseController::WISH_TO_OWN_FLOOR

  api_path "/stats/wish-to-own-ratio" do
    get("Stats Wish to Own Ratio") do
      operationId "wishToOwnRatio"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/wish-to-own-ratio returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/wish-to-own-ratio counts wishes per hundred owned" do
    model = create(:model)
    create_list(:vehicle, FLOOR, model:, wanted: false, loaner: false)
    create_list(:vehicle, FLOOR / 2, model:, wanted: true, loaner: false)

    assert_api_response :get, 200 do
      assert_equal [model.name], parsed_body.map { |point| point["label"] }
      assert_equal [50], parsed_body.map { |point| point["count"] }
    end
  end

  # The whole point of the floor: without it a ship three people own and four
  # want tops a chart about demand.
  test "GET /stats/wish-to-own-ratio ignores a ship too few people own" do
    model = create(:model)
    create_list(:vehicle, 3, model:, wanted: false, loaner: false)
    create_list(:vehicle, 4, model:, wanted: true, loaner: false)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /stats/wish-to-own-ratio ranks the more wanted ship first" do
    dreamed_of = create(:model)
    owned = create(:model)
    create_list(:vehicle, FLOOR, model: dreamed_of, wanted: false, loaner: false)
    create_list(:vehicle, FLOOR, model: dreamed_of, wanted: true, loaner: false)
    create_list(:vehicle, FLOOR, model: owned, wanted: false, loaner: false)
    create(:vehicle, model: owned, wanted: true, loaner: false)

    assert_api_response :get, 200 do
      assert_equal [dreamed_of.name, owned.name], parsed_body.map { |point| point["label"] }
      assert_equal [100, 1], parsed_body.map { |point| point["count"] }
    end
  end
end
