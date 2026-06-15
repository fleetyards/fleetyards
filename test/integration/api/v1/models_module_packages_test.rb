# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsModulePackagesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/module-packages" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Module Packages") do
      operationId "modelModulePackages"
      tags "Models"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModulePackages"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /models/:slug/module-packages returns packages" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/module-packages returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
