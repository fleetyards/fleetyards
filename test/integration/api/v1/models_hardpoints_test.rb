# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsHardpointsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/hardpoints" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Hardpoints") do
      operationId "modelHardpoints"
      tags "Models"
      produces "application/json"

      parameter name: "source", in: :query,
        schema: {"$ref": "#/components/schemas/HardpointSourceEnum"}, required: false

      response(200, "successful") do
        schema type: :array,
          items: {
            anyOf: [
              {"$ref": "#/components/schemas/Hardpoint"},
              {"$ref": "#/components/schemas/ModelHardpoint"}
            ]
          }
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/hardpoints returns hardpoints" do
    model = create(:model, :with_hardpoints)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_equal model.model_hardpoints.size, parsed_body.count
    end
  end

  test "GET /models/:slug/hardpoints returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
