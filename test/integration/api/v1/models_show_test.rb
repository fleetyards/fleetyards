# frozen_string_literal: true

require_relative "../../../openapi_helper"

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

  test "GET /models/:slug returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
