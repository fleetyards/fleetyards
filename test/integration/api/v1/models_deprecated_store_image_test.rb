# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsDeprecatedStoreImageTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/store-image" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Storeimage") do
      operationId "modelStoreImage"
      deprecated true
      tags "Models"

      response(302, "successful")
    end
  end

  test "GET /models/:slug/store-image redirects" do
    model = create(:model, :with_legacy_images)

    assert_api_response :get, 302, path_params: {slug: model.slug}
  end

  test "GET /models/:slug/store-image redirects a ship without a store image to its coloured angled view" do
    model = create(:model)
    model.angled_view_colored.attach(io: file_fixture("test.png").open, filename: "angled-colored.png", content_type: "image/png")

    get "/api/v1/models/#{model.slug}/store-image"

    assert_response :redirect
    assert_includes response.location, "angled-colored.png"
  end
end
