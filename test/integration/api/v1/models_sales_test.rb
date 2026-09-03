# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsSalesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/sales" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Sales") do
      operationId "modelSales"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::Sales::ModelSales
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/sales returns the recorded sales, newest first" do
    model = create(:model)
    create(:model_sale, :finished, model:, started_at: 1.year.ago, ended_at: 11.months.ago)
    create(:model_sale, model:, started_at: 2.days.ago, ended_at: nil)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 2, parsed_body["salesCount"]
      assert_equal 2, parsed_body["sales"].count
      assert parsed_body["sales"].first["ongoing"]
      assert_nil parsed_body["sales"].first["durationInDays"]
      assert_in_delta 30.0, parsed_body["sales"].last["durationInDays"], 2.0
    end
  end

  test "GET /models/:slug/sales reports the gap between sales" do
    model = create(:model)
    create(:model_sale, :finished, model:, started_at: 100.days.ago, ended_at: 96.days.ago)
    create(:model_sale, :finished, model:, started_at: 60.days.ago, ended_at: 56.days.ago)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 40.0, parsed_body["averageDaysBetweenSales"]
    end
  end

  # Nothing recorded the flag before this table existed, so a ship with no
  # history has to answer rather than look broken.
  test "GET /models/:slug/sales answers for a ship that has never been on sale" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 0, parsed_body["salesCount"]
      assert_empty parsed_body["sales"]
      assert_nil parsed_body["lastSaleAt"]
      assert_nil parsed_body["averageDaysBetweenSales"]
    end
  end

  test "GET /models/:slug/sales returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
