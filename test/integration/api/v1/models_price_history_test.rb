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

  test "GET /models/:slug/price-history returns the changes oldest first" do
    model = create(:model, pledge_price: 100)
    model.update!(pledge_price: 150)
    model.update!(pledge_price: 200)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [100, 150], parsed_body.map { |point| point["from"].to_i }
      assert_equal [150, 200], parsed_body.map { |point| point["to"].to_i }
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
