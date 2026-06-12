# frozen_string_literal: true

require_relative "../../../openapi_helper"

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
end
