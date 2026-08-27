# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsVariantsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/variants" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Variants") do
      operationId "modelVariants"
      tags "Models"
      produces "application/json"

      parameter ::Shared::V1::Parameters::PageParameter
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Models
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/variants returns variants" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/variants returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
