# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug returns the model" do
    model = create(:model, :with_description, :with_store_image, :with_fleetchart_image)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  # The matrix figure and the game-file measurement disagree for a third of
  # ships, so both are served rather than one overwriting the other.
  test "GET /models/:slug carries the game-file measurements alongside the matrix ones" do
    model = create(:model, length: 111.5, beam: 39.5, height: 20.0,
      sc_length: 13.4, sc_beam: 39.5, sc_height: 111.5)

    get "/api/v1/models/#{model.slug}"

    assert_response :success
    metrics = response.parsed_body["metrics"]

    assert_in_delta 111.5, metrics["length"]
    assert_in_delta 13.4, metrics.dig("gameFiles", "length")
    assert_in_delta 111.5, metrics.dig("gameFiles", "height")
  end

  # Zero is the one unmeasured case the export makes recognisable, and a zero
  # dimension would read as a real disagreement.
  test "GET /models/:slug leaves out game-file measurements the export does not have" do
    model = create(:model, sc_length: 0, sc_beam: 0, sc_height: 0)

    get "/api/v1/models/#{model.slug}"

    assert_response :success
    assert_nil response.parsed_body["metrics"]["gameFiles"]
  end

  test "GET /models/:slug returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
