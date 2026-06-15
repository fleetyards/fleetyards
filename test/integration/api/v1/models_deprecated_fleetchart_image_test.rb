# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsDeprecatedFleetchartImageTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/fleetchart-image" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Fleetchart Image") do
      operationId "modelFleetchartImage"
      deprecated true
      tags "Models"

      response(302, "successful")

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        produces "application/json"
      end
    end
  end

  test "GET /models/:slug/fleetchart-image redirects" do
    model = create(:model, :with_legacy_images)

    assert_api_response :get, 302, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/fleetchart-image returns 404 for unknown" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
