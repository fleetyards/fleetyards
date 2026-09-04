# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsPriceHistoryTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/price-history" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Price History") do
      operationId "modelPriceHistory"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Prices::ModelPricePointsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/price-history returns the days oldest first" do
    model = create(:model, pledge_price: 100)
    travel_to(3.days.ago) { model.update!(pledge_price: 150) }
    model.update!(pledge_price: 200)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [100, 150], parsed_body.map { |point| point["from"].to_i }
      assert_equal [150, 200], parsed_body.map { |point| point["to"].to_i }
    end
  end

  # The loader writes what the store showed at scrape time and scrapes several
  # times a day. The 100i went 59.59 -> 65.01 -> 65.00 -> 50.00 inside four
  # hours, which is one price change and three artefacts of currency and
  # rounding.
  test "GET /models/:slug/price-history reports one move per day" do
    model = create(:model, pledge_price: 100)
    model.update!(pledge_price: 59.59)
    model.update!(pledge_price: 65.01)
    model.update!(pledge_price: 50)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 1, parsed_body.count
      assert_equal 100, parsed_body.sole["from"].to_i
      assert_equal 50, parsed_body.sole["to"].to_i
    end
  end

  test "GET /models/:slug/price-history leaves out a day that ended where it began" do
    model = create(:model, pledge_price: 100)
    model.update!(pledge_price: 80)
    model.update!(pledge_price: 100)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body
    end
  end

  # A ship first given a price has no earlier price, and null says so. Reading
  # it as a rise from zero would be wrong.
  test "GET /models/:slug/price-history reports a first price with no earlier one" do
    model = create(:model, pledge_price: nil)
    model.update!(pledge_price: 90)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_nil parsed_body.sole["from"]
      assert_equal 90, parsed_body.sole["to"].to_i
    end
  end

  test "GET /models/:slug/price-history reports a price that was taken away" do
    model = create(:model, pledge_price: 90)
    model.update!(pledge_price: nil)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 90, parsed_body.sole["from"].to_i
      assert_nil parsed_body.sole["to"]
    end
  end

  test "GET /models/:slug/price-history ignores changes to anything else" do
    model = create(:model, pledge_price: 100)
    model.update!(name: "Renamed")

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /models/:slug/price-history returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
