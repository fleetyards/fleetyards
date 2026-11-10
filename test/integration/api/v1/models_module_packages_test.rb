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

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelModule.default_per_page}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::ModulePackages::ModelModulePackages
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /models/:slug/module-packages returns packages" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/module-packages sends how wide a package's angled picture is" do
    package = create(:model_module_package)
    package.top_view.attach(io: file_fixture("test.png").open, filename: "top.png", content_type: "image/png")
    package.top_view.blob.update!(metadata: package.top_view.blob.metadata.merge(angled_extent: 1.054))

    assert_api_response :get, 200, path_params: {slug: package.model.slug}

    assert_in_delta 1.054, response.parsed_body["items"].first.dig("media", "angledExtent")
  end

  test "GET /models/:slug/module-packages returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
