# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsPositionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/positions" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Positions") do
      operationId "modelPositions"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ModelPosition"}
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/positions returns positions" do
    model = create(:model)
    create(:model_position, model: model)
    create(:model_position, :copilot, model: model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal 2, parsed_body.count
      assert_equal "Pilot", parsed_body.first["name"]
    end
  end

  test "GET /models/:slug/positions returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
