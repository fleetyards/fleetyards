# frozen_string_literal: true

require "openapi_helper"

class Api::V1::StatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/stats/quick-stats" do
    get("Stats") do
      operationId "stats"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Stats
      end
    end
  end

  test "GET /stats/quick-stats returns the quick stats" do
    assert_api_response :get, 200
  end

  test "GET /stats/quick-stats reports how many hangared ships carry a paint" do
    model = create(:model)
    paint = create(:model_paint, model:)
    create(:vehicle, model:, model_paint: paint, wanted: false, loaner: false)
    create_list(:vehicle, 3, model:, model_paint: nil, wanted: false, loaner: false)

    assert_api_response :get, 200 do
      assert_equal 25.0, parsed_body["paintedVehiclesPercent"]
    end
  end

  # A loaner's paint is not a choice anyone made, so it counts on neither side.
  test "GET /stats/quick-stats leaves loaners out of the paint share" do
    model = create(:model)
    create(:vehicle, model:, model_paint: create(:model_paint, model:), wanted: false, loaner: false)
    create(:vehicle, model:, model_paint: nil, wanted: false, loaner: true)

    assert_api_response :get, 200 do
      assert_equal 100.0, parsed_body["paintedVehiclesPercent"]
    end
  end
end
