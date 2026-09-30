# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MarkdownImagesShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/markdown-images/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Markdown image id", required: true

    get("Show an image embedded in a Markdown description") do
      operationId "markdownImage"
      tags "MarkdownImages"

      response(302, "redirects to the image's rendition")

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
        produces "application/json"
      end
    end
  end

  test "GET /markdown-images/:id redirects to its rendition, signed in or not" do
    image = create(:markdown_image)

    assert_api_response :get, 302, path_params: {id: image.id} do
      assert_includes response.location, "/representations/"
    end
  end

  test "GET /markdown-images/:id returns 404 once the image is gone" do
    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end
end
