# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsWishlistByModelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/wishlist-by-model" do
    get("Stats Wishlist by Model") do
      operationId "wishlistByModel"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end
    end
  end

  test "GET /stats/wishlist-by-model returns chart data" do
    assert_api_response :get, 200
  end

  test "GET /stats/wishlist-by-model ranks ships by how many want them" do
    wanted = create(:model)
    less_wanted = create(:model)
    create_list(:vehicle, 3, model: wanted, wanted: true, loaner: false)
    create(:vehicle, model: less_wanted, wanted: true, loaner: false)

    assert_api_response :get, 200 do
      assert_equal [wanted.name, less_wanted.name], parsed_body.map { |point| point["label"] }
      assert_equal [3, 1], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /stats/wishlist-by-model leaves out ships people already own" do
    model = create(:model)
    create(:vehicle, model:, wanted: true, loaner: false)
    create(:vehicle, model:, wanted: false, loaner: false)

    assert_api_response :get, 200 do
      assert_equal [1], parsed_body.map { |point| point["count"] }
    end
  end

  # 598k of the 1.57M vehicles are loaners, which would swamp every ranking.
  test "GET /stats/wishlist-by-model leaves out loaners" do
    model = create(:model)
    create(:vehicle, model:, wanted: true, loaner: true)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end
end
