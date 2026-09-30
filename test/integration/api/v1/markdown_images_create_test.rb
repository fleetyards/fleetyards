# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MarkdownImagesCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/markdown-images" do
    post("Upload an image for a Markdown description") do
      operationId "createMarkdownImage"
      tags "MarkdownImages"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::MarkdownImageCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::MarkdownImage
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /markdown-images stores the image for the current user" do
    sign_in @user

    assert_difference -> { @user.markdown_images.count }, 1 do
      assert_api_response :post, 201, body: {file: upload("test.png", "image/png").signed_id} do
        assert_equal @user.markdown_images.last.id, parsed_body["id"]
        assert_match %r{/markdown-images/#{parsed_body["id"]}/?\z}, parsed_body["url"]
        assert_equal 2000, parsed_body["width"]
        assert_equal 1405, parsed_body["height"]
      end
    end
  end

  test "POST /markdown-images returns 400 for an SVG" do
    sign_in @user

    assert_api_response :post, 400, body: {file: upload("vector.svg", "image/svg+xml").signed_id} do
      assert_equal "validation_error.markdown_image.create", parsed_body["code"]
      assert_includes error_codes("file"), "svg_not_supported"
    end
  end

  test "POST /markdown-images returns 400 for a PDF" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: "doc.pdf", content_type: "application/pdf")
    sign_in @user

    assert_api_response :post, 400, body: {file: blob.signed_id} do
      assert_includes error_codes("file"), "image_type_not_supported"
    end
  end

  test "POST /markdown-images returns 400 once the daily limit is reached" do
    now = Time.current
    MarkdownImage.insert_all(Array.new(MarkdownImage::DAILY_LIMIT) { {user_id: @user.id, created_at: now, updated_at: now} })
    sign_in @user

    assert_no_difference -> { MarkdownImage.count } do
      assert_api_response :post, 400, body: {file: upload("test.png", "image/png").signed_id} do
        assert_includes error_codes("base"), "markdown_image_limit_reached"
      end
    end
  end

  test "POST /markdown-images returns 401 when not signed in" do
    assert_api_response :post, 401, body: {file: upload("test.png", "image/png").signed_id}
  end

  test "POST /markdown-images with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:write"]),
      body: {file: upload("test.png", "image/png").signed_id}
  end

  private def upload(fixture, content_type)
    ActiveStorage::Blob.create_and_upload!(io: file_fixture(fixture).open, filename: fixture, content_type:)
  end

  private def error_codes(attribute)
    parsed_body["errors"].find { |error| error["attribute"] == attribute }&.dig("messages")&.map { |message| message["code"] } || []
  end
end
