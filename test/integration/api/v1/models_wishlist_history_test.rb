# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsWishlistHistoryTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/wishlist-history" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Wishlist History") do
      operationId "modelWishlistHistory"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::BarChartStatsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/wishlist-history returns the months oldest first" do
    model = create(:model)
    record_additions(model, 3, at: 3.months.ago)
    record_additions(model, 8, at: 1.month.ago)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [3, 8], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /models/:slug/wishlist-history leaves out other ships" do
    model = create(:model)
    other = create(:model)
    record_additions(model, 5, at: 1.month.ago)
    record_additions(other, 40, at: 1.month.ago)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal [5], parsed_body.map { |point| point["count"] }
    end
  end

  test "GET /models/:slug/wishlist-history answers for a ship nobody has wishlisted" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /models/:slug/wishlist-history returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end

  private def record_additions(model, additions, at:)
    Rollup.create!(
      name: MetricsJob::ROLLUP_WISHLIST_BY_MODEL,
      interval: "month",
      time: at.beginning_of_month,
      value: additions,
      dimensions: {model_id: model.id}
    )
  end
end
