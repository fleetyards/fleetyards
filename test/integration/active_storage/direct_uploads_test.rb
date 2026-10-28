# frozen_string_literal: true

require "test_helper"

class ActiveStorageDirectUploadsTest < ActionDispatch::IntegrationTest
  test "a player can upload an image and a hangar import" do
    sign_in create(:user)

    %w[image/png image/webp application/json].each do |content_type|
      post_blob(content_type)

      assert_response :success, content_type
      assert_equal content_type, response.parsed_body["content_type"]
    end
  end

  test "a player cannot upload markup, admin files or an untyped file" do
    sign_in create(:user)

    ["text/html", "image/svg+xml", "text/html;charset=utf-8", "application/xhtml+xml",
      "application/pdf", "model/gltf-binary", "application/octet-stream", "video/mp4", ""].each do |content_type|
      assert_no_difference -> { ActiveStorage::Blob.count } do
        post_blob(content_type)
      end

      assert_response :unprocessable_content, content_type
    end
  end

  test "an admin can upload a brochure and a holo model, typed or not" do
    sign_in create(:admin_user), scope: :admin_user

    ["application/pdf", "model/gltf-binary", "model/gltf+json", "application/octet-stream", "", "image/png"].each do |content_type|
      post_blob(content_type)

      assert_response :success, content_type
    end
  end

  test "an admin cannot upload markup either" do
    sign_in create(:admin_user), scope: :admin_user

    %w[text/html image/svg+xml].each do |content_type|
      post_blob(content_type)

      assert_response :unprocessable_content, content_type
    end
  end

  private def post_blob(content_type)
    body = "x"
    post rails_direct_uploads_path, params: {
      blob: {filename: "upload", byte_size: body.bytesize, checksum: Digest::MD5.base64digest(body), content_type:}
    }, as: :json
  end
end
