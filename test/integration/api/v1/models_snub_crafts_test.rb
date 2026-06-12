# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::ModelsSnubCraftsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/snub-crafts" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Snubcrafts") do
      operationId "modelSnubCrafts"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/snub-crafts returns snub crafts" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/snub-crafts returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
